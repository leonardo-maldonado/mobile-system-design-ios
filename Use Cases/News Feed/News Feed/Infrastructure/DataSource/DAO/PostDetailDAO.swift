//
//  PostDetailDAO.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/9/25.
//

import Foundation
import SwiftData

@Model
final class PostDetailDAO {
    @Attribute(.unique) var id: String
    var content: String
    var authorId: String
    var authorName: String
    var authorProfileImageThumbnailURL: String?
    var createdAt: Date
    var likesCount: Int
    var liked: Bool
    var sharedCount: Int
    @Relationship(deleteRule: .cascade) var attachments: [PostAttachmentDAO]

    init(
        id: String,
        content: String,
        authorId: String,
        authorName: String,
        authorProfileImageThumbnailURL: String?,
        createdAt: Date,
        likesCount: Int,
        liked: Bool,
        sharedCount: Int,
        attachments: [PostAttachmentDAO]
    ) {
        self.id = id
        self.content = content
        self.authorId = authorId
        self.authorName = authorName
        self.authorProfileImageThumbnailURL = authorProfileImageThumbnailURL
        self.createdAt = createdAt
        self.likesCount = likesCount
        self.liked = liked
        self.sharedCount = sharedCount
        self.attachments = attachments
    }
}

@Model
final class PostAttachmentDAO {
    var contentUrl: String
    var type: String
    var caption: String?

    init(contentUrl: String, type: String, caption: String?) {
        self.contentUrl = contentUrl
        self.type = type
        self.caption = caption
    }
}

