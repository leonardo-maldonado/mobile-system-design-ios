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
                } else if state.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = state.error {
                    Text("Error: \(error.localizedDescription)")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding()
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadPost()
        }
        .onAppear {
            setupSubscription()
        }
        .onDisappear {
            cancellable?.cancel()
        }
    }
    
    private func loadPost() async {
        state.isLoading = true
        state.error = nil
        
        do {
            let detail = try await repository.fetchPostDetail(id: postId)
            state.detail = detail
        } catch {
            state.error = error
        }
        
        state.isLoading = false
    }
    
    private func setupSubscription() {
        guard let repo = repository as? PostRepository else { return }
        
        cancellable = repo.interactionChanges
            .receive(on: DispatchQueue.main)
            .sink { event in
                if event.postId == postId {
                    state.detail?.liked = event.liked
                    state.detail?.likesCount = event.likeCount
                }
            }
    }
    
    private func toggleLike(_ detail: PostDetail) async {
        let action: UserInteraction.Action = detail.liked ? .unlike : .like
        
        do {
            try await repository.interactWithPost(postId, action: action)
        } catch {
            state.error = error
        }
    }
}

private struct ViewState {
    var detail: PostDetail?
    var isLoading = false
    var error: Error?
}


