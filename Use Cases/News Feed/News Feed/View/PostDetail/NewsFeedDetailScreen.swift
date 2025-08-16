//
//  NewsFeedDetailScreen.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/9/25.
//

import SwiftUI
import Combine

struct NewsFeedDetailScreen: View {
    @State private var state = ViewState()
    @State private var cancellable: AnyCancellable?
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
                    DetailHeaderView(name: detail.author.name, createdAt: detail.createdAt)
                    DetailBodyView(content: detail.content, firstAttachmentURL: detail.attachments.first?.contentUrl)
                    DetailActionsView(liked: detail.liked, likes: detail.likesCount, shares: detail.sharedCount) {
                        Task { await toggleLike(detail) }
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .onAppear { 
            setupSubscription() 
        }
        .onDisappear { 
            cancellable?.cancel() 
        }
        .overlay {
            if state.isLoading { ProgressView() }
        }
    }

    private func load() async {
        await MainActor.run { state.isLoading = true }
        defer { Task { await MainActor.run { state.isLoading = false } } }
        do {
            let d = try await repository.fetchPostDetail(id: postId)
            await MainActor.run { 
                state.detail = d
            }
        } catch {
            await MainActor.run { state.errorMessage = error.localizedDescription }
        }
    }

    private func toggleLike(_ detail: PostDetail) async {
        let action: UserInteraction.Action = detail.liked ? .unlike : .like
        try? await repository.interactWithPost(postId, action: action)
    }
    
    private func setupSubscription() {
        guard let repo = repository as? PostRepository else { 
            return 
        }
        
        cancellable = repo.interactionChanges
            .receive(on: DispatchQueue.main)
            .sink { evt in
                if evt.postId == self.postId {
                    if var detail = self.state.detail {
                        detail.liked = evt.liked
                        detail.likesCount = evt.likeCount
                        self.state.detail = detail
                    }
                }
            }
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

