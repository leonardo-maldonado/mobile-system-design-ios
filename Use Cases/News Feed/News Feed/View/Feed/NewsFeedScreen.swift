//
//  ContentView.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/8/25.
//

import SwiftUI
import Combine

struct NewsFeedScreen: View {
    @State private var state = ViewState()
    @Environment(\.viewInteraction) private var interaction
    private let repository: PostRepositoryFetching
    @State private var cancellable: AnyCancellable?

    init(repository: PostRepositoryFetching) {
        self.repository = repository
    }

    var body: some View {
        Group {
            if state.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = state.errorMessage {
                ErrorStateView(message: error) {
                    Task { await reload() }
                }
            } else if state.posts.isEmpty {
                emptyView
            } else {
                listView
            }
        }
        .task {
            await fetchPosts()
        }
        .onAppear {
            setupSubscription()
        }
        .refreshable { await reload() }
        .overlay(alignment: .bottomTrailing) { 
            ComposeButtonView {
                interaction?.send(.feed(.composeRequested))
            }
        }
    }
    
    private func setupSubscription() {
        guard cancellable == nil else {
            return
        }
        
        guard let repo = repository as? PostRepository else { 
            return 
        }
        
        cancellable = repo.interactionChanges
            .receive(on: DispatchQueue.main)
            .sink { evt in
                if let idx = state.posts.firstIndex(where: { $0.postId == evt.postId }) {
                    state.posts[idx].liked = evt.liked
                    state.posts[idx].likeCount = evt.likeCount
                }
            }
    }

    // MARK: - Sub-views

    private var listView: some View {
        List {
            ForEach(state.posts, id: \.postId) { item in
                Button { interaction?.send(.feed(.postSelected(id: item.postId))) } label: {
                    FeedRowView(item: item, onLike: {
                        Task {
                            if let idx = state.posts.firstIndex(where: { $0.postId == item.postId }) {
                                let wasLiked = state.posts[idx].liked
                                state.posts[idx].liked.toggle()
                                state.posts[idx].likeCount += state.posts[idx].liked ? 1 : -1
                                
                                let action: UserInteraction.Action = state.posts[idx].liked ? .like : .unlike
                                try? await repository.interactWithPost(item.postId, action: action)
                            }
                        }
                    })
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.plain)
    }

    private var emptyView: some View {
        ContentUnavailableView("Empty News Feed", image: "square.and.arrow.up.on.square")
    }

    // MARK: - Actions
    
    private func fetchPosts() async {
        guard state.posts.isEmpty else { return }
        await reload()
    }

    private func reload() async {
        await MainActor.run { state.isLoading = true; state.errorMessage = nil }
        do {
            let posts = try await repository.fetchPosts()
            await MainActor.run { 
                state.posts = posts
            }
        } catch {
            await MainActor.run { state.errorMessage = error.localizedDescription }
        }
        await MainActor.run { state.isLoading = false }
    }
}

// MARK: - Local View State

extension NewsFeedScreen {
    struct ViewState {
        var isLoading = false
        var errorMessage: String?
        var posts: [PostPreview] = []
    }
}

#Preview {
    let repo = Container.shared.resolve(PostRepositoryFetching.self)
    return NewsFeedScreen(repository: repo)
}
