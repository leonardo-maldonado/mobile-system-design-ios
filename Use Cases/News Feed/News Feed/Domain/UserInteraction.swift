//
//  UserInteraction.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/9/25.
//

struct UserInteraction {
    var id: String
    var postId: String
    var userId: String
    var action: Action
    var status: Status
    var createdAt: String
    var updatedAt: String
    var failureCount: Int
    
    enum Action: String, Codable {
        case like
        case unlike
        case shared
        case bookmarked
    }
    
    enum Status: String, Codable {
        case pending
        case cancelled
        case completed
        case failed
    }
}
