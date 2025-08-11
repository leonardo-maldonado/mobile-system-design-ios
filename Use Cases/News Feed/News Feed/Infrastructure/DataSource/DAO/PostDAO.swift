//
//  PostDAO.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/8/25.
//

import Foundation
import SwiftData

@Model
final class PostDAO {
    @Attribute(.unique) var id: String
    var contentSummary: String
    var author: String
    var createdAt: Date
    var liked: Bool
    var likeCount: Int
    var attachmentCount: Int
    var attachmentPreviewImageUrl: String?

    init(
        id: String,
        contentSummary: String,
        author: String,
        createdAt: Date,
        liked: Bool,
        likeCount: Int,
        attachmentCount: Int,
        attachmentPreviewImageUrl: String?
    ) {
        self.id = id
        self.contentSummary = contentSummary
        self.author = author
        self.createdAt = createdAt
        self.liked = liked
        self.likeCount = likeCount
        self.attachmentCount = attachmentCount
        self.attachmentPreviewImageUrl = attachmentPreviewImageUrl
    }
}

private let postISO8601: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f
}()

extension PostDAO {
    func toDomain() -> PostPreview {
        PostPreview(
            postId: id,
            contentSummary: contentSummary,
            author: author,
            createdAt: postISO8601.string(from: createdAt),
            liked: liked,
            likeCount: likeCount,
            attachtmentCount: attachmentCount,
            attachmentPreviewImageUrl: attachmentPreviewImageUrl
        )
    }
}
