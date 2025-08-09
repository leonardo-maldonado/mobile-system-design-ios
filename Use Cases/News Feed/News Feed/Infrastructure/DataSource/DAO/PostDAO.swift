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
    var authorId: String
    var authorName: String
    var createdAt: Date
    var liked: Bool
    var likeCount: Int
    var attachmentCount: Int
    var attachmentPreviewImageUrl: String?

    init(
        id: String,
        contentSummary: String,
        authorId: String,
        authorName: String,
        createdAt: Date,
        liked: Bool,
        likeCount: Int,
        attachmentCount: Int,
        attachmentPreviewImageUrl: String?
    ) {
        self.id = id
        self.contentSummary = contentSummary
        self.authorId = authorId
        self.authorName = authorName
        self.createdAt = createdAt
        self.liked = liked
        self.likeCount = likeCount
        self.attachmentCount = attachmentCount
        self.attachmentPreviewImageUrl = attachmentPreviewImageUrl
    }
}
