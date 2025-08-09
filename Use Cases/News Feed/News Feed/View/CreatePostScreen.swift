//
//  CreatePostScreen.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/9/25.
//

import SwiftUI

struct CreatePostScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var state = ViewState()
    private let repository: PostRepositoryFetching

    init(repository: PostRepositoryFetching) {
        self.repository = repository
    }

    var body: some View {
        Form {
            Section("Content") {
                TextField("What's happening?", text: $state.content, axis: .vertical)
                    .lineLimit(5...10)
            }
            Section("Attachments (URL)") {
                ForEach($state.attachments.indices, id: \.self) { idx in
                    HStack {
                        TextField("URL", text: $state.attachments[idx].contentUrl)
                        TextField("Type", text: $state.attachments[idx].type)
                    }
                }
                Button("Add attachment") { state.attachments.append(.init(contentUrl: "", type: "image", caption: nil)) }
            }
        }
        .navigationTitle("New Post")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("Cancel", role: .cancel) { dismiss() } }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Publish") { Task { await submit() } }
                    .disabled(state.isSubmitting || state.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .overlay(alignment: .bottom) {
            if let error = state.errorMessage { banner(error) }
        }
        .overlay {
            if state.isSubmitting { ProgressView().controlSize(.large) }
        }
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
        var content: String = ""
        var attachments: [PostAttachement] = []
        var isSubmitting = false
        var errorMessage: String?
    }
}

#Preview {
    let repo = PostRepository(
        remoteDataSource: PostRemoteDataSource(),
        localDataSource: PostLocalDataSource()
    )
    return NavigationStack { CreatePostScreen(repository: repo) }
}