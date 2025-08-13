//
//  ContentView.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/8/25.
//

import SwiftUI

struct NewsFeedScreen: View {
    @State private var state = ViewState()
    @Environment(\.viewInteraction) private var interaction
    private let repository: PostRepositoryFetching

    init(repository: PostRepositoryFetching) {
        self.repository = repository
    }

    var body: some View {
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { interaction?.send(.feed(.openCreatePost)) } label: { Image(systemName: "square.and.pencil") }
            }
        }
        .task { await loadInitial() }
        .refreshable { await reload() }
        .overlay(alignment: .bottomTrailing) { composeButton }
    }

    private var listView: some View {
        List {
            ForEach(state.posts, id: \.postId) { item in
                Button { interaction?.send(.feed(.openDetail(item.postId))) } label: {
                    FeedRow(item: item)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.plain)
    }

    struct FeedRow: View {
        let item: PostPreview
        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                Circle().fill(Color.gray.opacity(0.2)).frame(width: 44, height: 44)
                    .overlay(Text(String(item.author.prefix(1))).font(.headline))
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(item.author).font(.headline)
                        Spacer()
                        Text(Self.relative(item.createdAt)).font(.caption).foregroundStyle(.secondary)
                    }
                    Text(item.contentSummary).font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                    if let urlString = item.attachmentPreviewImageUrl, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty: Rectangle().fill(Color.gray.opacity(0.15)).frame(height: 180).redacted(reason: .placeholder)
                            case .success(let img): img.resizable().scaledToFill().frame(height: 180).clipped().cornerRadius(8)
                            case .failure: Rectangle().fill(Color.gray.opacity(0.15)).frame(height: 180).overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                            @unknown default: EmptyView()
                            }
                        }
                    }
                    HStack(spacing: 18) {
                        Label("\(item.likeCount)", systemImage: item.liked ? "heart.fill" : "heart")
                            .foregroundStyle(item.liked ? .red : .secondary)
                        if item.attachtmentCount > 0 {
                            Label("\(item.attachtmentCount)", systemImage: "photo")
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }

        private static let iso = ISO8601DateFormatter()
        private static let rel = RelativeDateTimeFormatter()
        private static func relative(_ isoString: String) -> String {
            if let date = iso.date(from: isoString) { return rel.localizedString(for: date, relativeTo: Date()) }
            return isoString
        }
    }

    private var composeButton: some View {
        Button {
            interaction?.send(.feed(.openCreatePost))
        } label: {
            Image(systemName: "square.and.pencil").font(.title2)
                .padding(16)
                .background(.thinMaterial, in: Circle())
        }
        .padding(16)
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
    struct ViewState {
        var isLoadingInitial = false
        var errorMessage: String?
        var posts: [PostPreview] = []
    }
}

#Preview {
    let repo = PostRepository(
        remoteDataSource: PostRemoteDataSource(),
        localDataSource: PostLocalDataSource()
    )
    return NewsFeedScreen(repository: repo)
}
