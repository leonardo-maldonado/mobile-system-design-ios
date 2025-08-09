//
//  PostRemoteDataSource.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/8/25.
//

import Foundation

protocol PostRemoteDataFetching {
    func fetchFeed(pageToken: String?) async throws -> FeedAPIResponse
    func fetchPostDetail(id: String) async throws -> PostDetailAPIResponse
    func createPost(_ request: NewPostRequest) async throws
    func interact(_ request: PostInteractionRequest) async throws
}

actor PostRemoteDataSource: PostRemoteDataFetching {
    func fetchFeed(pageToken: String?) async throws -> FeedAPIResponse {
        return FeedAPIResponse(feed: [], paging: FeedAPIResponse.PaginationMetaData())
    }
    
    func fetchPostDetail(id: String) async throws -> PostDetailAPIResponse {
        return PostDetailAPIResponse(
            post:
                PostDetail(
                    id: "",
                    content: "",
                    author:
                        AuthorPreview(id: "", name: ""),
                    createdAt: "",
                    likesCount: 0,
                    liked: true,
                    sharedCount: 1,
                    attachments: [])
        )
    }
    
    func createPost(_ request: NewPostRequest) async throws {
        // TODO: Impl.
    }
    
    func interact(_ request: PostInteractionRequest) async throws {
        // TODO: Impl.
    }
}
