//
//  PostLocalDataSource.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/8/25.
//

protocol PostLocalDataStoring {
    func loadFeed() async throws -> [PostDAO]
    func loadPost(id: String) async throws -> PostDetailDAO?
    func saveFeed(_ posts: [PostDAO]) async throws
    func createPost(_ request: NewPostRequest) async throws
    func interact(_ request: PostInteractionRequest) async throws
}

class PostLocalDataSource: PostLocalDataStoring {
    func loadFeed() async throws -> [PostDAO] {
        return []
    }
    
    func loadPost(id: String) async throws -> PostDetailDAO? {
        return nil
    }
    
    func saveFeed(_ posts: [PostDAO]) async throws {
        // TODO: Impl.
    }
    
    func createPost(_ request: NewPostRequest) async throws {
        // TODO: Impl.
    }
    
    func interact(_ request: PostInteractionRequest) async throws {
        // For demo purposes, just succeed without storing locally
        // In a real app, this would store the interaction in local database
    }
}
