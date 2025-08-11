//
//  CreatePostScreen.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/9/25.
//

import SwiftUI
import PhotosUI
import UIKit

struct CreatePostScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var state = ViewState()
    private let repository: PostRepositoryFetching

    init(repository: PostRepositoryFetching) {
        self.repository = repository
    }

    var body: some View {
        VStack(spacing: 0) {
            switch state.step {
            case .media:
                CreatePostMediaStep(selected: $state.selectedItems, images: $state.selectedImages) {
                    withAnimation { state.step = .edit }
                }
            case .edit:
                CreatePostEditStep(images: $state.selectedImages, brightness: $state.brightness, contrast: $state.contrast) {
                    state.generateAttachmentsFromSelected()
                    withAnimation { state.step = .compose }
                } onBack: {
                    withAnimation { state.step = .media }
                }
            case .compose:
                CreatePostComposeStep(content: $state.content, attachments: $state.attachments, isSubmitting: $state.isSubmitting, onSubmit: {
                    Task { await submit() }
                }, onBack: {
                    withAnimation { state.step = .edit }
                })
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel", role: .cancel) { dismiss() } } }
        .overlay(alignment: .bottom) { if let error = state.errorMessage { banner(error) } }
        .overlay { if state.isSubmitting { ProgressView().controlSize(.large) } }
    }

    private func banner(_ message: String) -> some View {
        Text(message)
            .font(.footnote)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.red.opacity(0.15), in: Capsule())
            .foregroundStyle(.red)
            .padding(.bottom, 12)
    }

    private func submit() async {
        await MainActor.run { state.isSubmitting = true; state.errorMessage = nil }
        do {
            let req = NewPostRequest(id: UUID().uuidString, content: state.content, attachements: state.attachments)
            try await repository.createPost(req)
            await MainActor.run { dismiss() }
        } catch {
            await MainActor.run { state.errorMessage = error.localizedDescription }
        }
        await MainActor.run { state.isSubmitting = false }
    }
}

// MARK: - Local View State
extension CreatePostScreen {
    struct ViewState {
        enum Step { case media, edit, compose }
        var step: Step = .media
        var content: String = ""
        var attachments: [PostAttachement] = []
        var isSubmitting = false
        var errorMessage: String?

        // Media
        var selectedItems: [PhotosPickerItem] = []
        var selectedImages: [UIImage] = []
        var brightness: Double = 0
        var contrast: Double = 1

        mutating func generateAttachmentsFromSelected() {
            attachments = selectedImages.enumerated().map { idx, _ in
                PostAttachement(contentUrl: "local://image_\(idx)", type: "image", caption: nil)
            }
        }
    }
}

private extension Binding where Value == String? {
    func or(_ fallback: String = "") -> Binding<String> {
        Binding<String>(
            get: { self.wrappedValue ?? fallback },
            set: { self.wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }
}

// Moved step views into separate files for readability: CreatePostMediaStep, CreatePostEditStep, CreatePostComposeStep

#Preview {
    let repo = PostRepository(
        remoteDataSource: PostRemoteDataSource(),
        localDataSource: PostLocalDataSource()
    )
    return NavigationStack { CreatePostScreen(repository: repo) }
}