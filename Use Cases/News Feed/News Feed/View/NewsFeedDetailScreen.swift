//
//  NewsFeedDetailScreen.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/9/25.
//

import SwiftUI

struct NewsFeedDetailScreen: View {
    @State private var state = ViewState()
    private let repository: PostRepositoryFetching
    private let postId: String

    init(repository: PostRepositoryFetching, postId: String) {
        self.repository = repository
        self.postId = postId
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let detail = state.detail {
                    Text(detail.author.name).font(.headline)
                    Text(detail.content).font(.body)
                    HStack(spacing: 16) {
                        Button(action: { Task { await toggleLike(detail) } }) {
                            Label("\(detail.likesCount)", systemImage: detail.liked ? "heart.fill" : "heart")
                                .foregroundStyle(detail.liked ? .red : .primary)
                        }
                        Label("\(detail.sharedCount)", systemImage: "arrowshape.turn.up.right")
                    }.font(.subheadline)
                }
            }
            .padding()
        }
        .navigationTitle("Post")
        .task { await load() }
        .overlay {
            if state.isLoading { ProgressView() }
        }
    }

    private func load() async {
        await MainActor.run { state.isLoading = true }
        defer { Task { await MainActor.run { state.isLoading = false } } }
        do {
            let d = try await repository.fetchPostDetail(id: postId)
            await MainActor.run { state.detail = d }
        } catch {
            await MainActor.run { state.errorMessage = error.localizedDescription }
        }
    }

    private func toggleLike(_ detail: PostDetail) async {
        let action: UserInteraction.Action = detail.liked ? .unlike : .like
        do { try await repository.interactWithPost(postId, action: action) } catch { }
        await load()
    }
}

// MARK: - Local View State
extension NewsFeedDetailScreen {
    struct ViewState {
        var isLoading = false
        var errorMessage: String?
        var detail: PostDetail?
    }
}

