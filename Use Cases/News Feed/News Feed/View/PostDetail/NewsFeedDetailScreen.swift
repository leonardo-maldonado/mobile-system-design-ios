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
                    DetailHeader(name: detail.author.name, createdAt: detail.createdAt)
                    DetailBody(content: detail.content, firstAttachmentURL: detail.attachments.first?.contentUrl)
                    DetailActions(liked: detail.liked, likes: detail.likesCount, shares: detail.sharedCount) {
                        Task { await toggleLike(detail) }
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
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

private extension NewsFeedDetailScreen {
    static let iso = ISO8601DateFormatter()
    static let rel = RelativeDateTimeFormatter()
    static func relative(_ isoString: String) -> String {
        if let date = iso.date(from: isoString) { return rel.localizedString(for: date, relativeTo: Date()) }
        return isoString
    }
}

// MARK: - Components
private struct DetailHeader: View {
    let name: String
    let createdAt: String
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Circle().fill(Color.gray.opacity(0.2)).frame(width: 44, height: 44)
                .overlay(Text(String(name.prefix(1))).font(.headline))
            VStack(alignment: .leading) {
                Text(name).font(.headline)
                Text(NewsFeedDetailScreen.relative(createdAt)).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

private struct DetailBody: View {
    let content: String
    let firstAttachmentURL: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(content).font(.body)
            if let s = firstAttachmentURL, let url = URL(string: s) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty: Rectangle().fill(Color.gray.opacity(0.15)).frame(height: 240).redacted(reason: .placeholder)
                    case .success(let img): img.resizable().scaledToFill().frame(height: 240).clipped().cornerRadius(10)
                    case .failure: Rectangle().fill(Color.gray.opacity(0.15)).frame(height: 240).overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                    @unknown default: EmptyView()
                    }
                }
            }
        }
    }
}

private struct DetailActions: View {
    let liked: Bool
    let likes: Int
    let shares: Int
    var onLike: () -> Void
    var body: some View {
        HStack(spacing: 20) {
            Button(action: onLike) { Label("\(likes)", systemImage: liked ? "heart.fill" : "heart") }
                .buttonStyle(.bordered)
            Label("\(shares)", systemImage: "arrowshape.turn.up.right").foregroundStyle(.secondary)
        }
        .font(.subheadline)
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

