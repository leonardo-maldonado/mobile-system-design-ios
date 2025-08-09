//
//  UserInteractionDAO.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/8/25.
//

import Foundation
import SwiftData

@Model
final class UserInteractionDAO {
    @Attribute(.unique) var id: String
    var postId: String
    var userId: String
    var action: String
    var status: String
    var createdAt: Date
    var updatedAt: Date
    var failureCount: Int

    init(
        id: String,
        postId: String,
        userId: String,
        action: String,
        status: String,
        createdAt: Date,
        updatedAt: Date,
        failureCount: Int
    ) {
        self.id = id
        self.postId = postId
        self.userId = userId
        self.action = action
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.failureCount = failureCount
    }
}
