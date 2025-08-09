//
//  ContentView.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/8/25.
//

import SwiftUI

struct NewsFeedScreen: View {
    @State private var state = ViewState()
    private let repository: PostRepositoryFetching

    init(repository: PostRepositoryFetching) {
        self.repository = repository
    }

    var body: some View {
        NavigationStack(path: $state.path) {
            Group {
                if state.isLoadingInitial {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = state.errorMessage {
                    errorView(error)
                } else if state.posts.isEmpty {
                    emptyView
                } else {
                    listView
                }
            }
            .navigationTitle("News Feed")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: Route.createPost) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .detail(let id):
                    NewsFeedDetailScreen(repository: repository, postId: id)
                case .createPost:
                    CreatePostScreen(repository: repository)
                }
            }
            .task { await loadInitial() }
            .refreshable { await reload() }
        }
    }

    private var listView: some View {
        List(state.posts, id: \.postId) { item in
            Button {
                state.path.append(.detail(item.postId))
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    Circle().fill(Color.gray.opacity(0.2)).frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.author).font(.headline)
                        Text(item.contentSummary).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                        HStack(spacing: 16) {
                            Label("\(item.likeCount)", systemImage: item.liked ? "heart.fill" : "heart")
                                .foregroundStyle(item.liked ? .red : .secondary)
                            if let url = item.attachmentPreviewImageUrl { Label(url, systemImage: "photo") }
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
            }
        }
        .listStyle(.plain)
    }

    private var emptyView: some View {
        ContentUnavailableView("Empty News Feed", image: "square.and.arrow.up.on.square")
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text(message).multilineTextAlignment(.center)
            Button("Retry") { Task { await reload() } }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions
    private func loadInitial() async {
        guard state.posts.isEmpty else { return }
        await reload()
    }

    private func reload() async {
        await MainActor.run { state.isLoadingInitial = true; state.errorMessage = nil }
        do {
            let posts = try await repository.fetchPosts()
            await MainActor.run { state.posts = posts }
        } catch {
            await MainActor.run { state.errorMessage = error.localizedDescription }
        }
        await MainActor.run { state.isLoadingInitial = false }
    }
}

// MARK: - Local View State
extension NewsFeedScreen {
    enum Route: Hashable { case detail(String), createPost }

    struct ViewState {
        var isLoadingInitial = false
        var errorMessage: String?
        var posts: [PostPreview] = []
        var path: [Route] = []
    }
}

#Preview {
    let repo = PostRepository(
        remoteDataSource: PostRemoteDataSource(),
        localDataSource: PostLocalDataSource()
    )
    return NewsFeedScreen(repository: repo)
}
