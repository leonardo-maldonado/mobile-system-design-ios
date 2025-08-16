//
//  FeedRowView.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/9/25.
//

import SwiftUI

struct FeedRowView: View {
    let item: PostPreview
    let onLike: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(item.author.prefix(1)))
                        .font(.headline)
                )
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Text(item.author)
                        .font(.headline)
                    Spacer()
                    Text(item.createdAt.timeAgo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Content summary
                Text(item.contentSummary)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                
                // Attachment image
                if let urlString = item.attachmentPreviewImageUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 180)
                                .redacted(reason: .placeholder)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 180)
                                .clipped()
                                .cornerRadius(8)
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 180)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundStyle(.secondary)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                
                // Actions
                HStack(spacing: 18) {
                    Button(action: onLike) {
                        Label("\(item.likeCount)", systemImage: item.liked ? "heart.fill" : "heart")
                            .foregroundStyle(item.liked ? .red : .secondary)
                    }
                    
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
}

#Preview {
    FeedRowView(
        item: PostPreview(
            postId: "1",
            contentSummary: "This is a sample post content that demonstrates how the FeedRowView component works with text and optional images.", author: "John Doe",
            createdAt: "2025-08-09T10:30:00Z",
            liked: false,
            likeCount: 42,
            attachtmentCount: 1,
            attachmentPreviewImageUrl: nil
        ),
        onLike: {}
    )
    .padding()
}
