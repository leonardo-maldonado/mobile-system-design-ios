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
    
    var httpClient: URLSessionHTTPClient
    
    init(httpClient: URLSessionHTTPClient = .init(config: HTTPClientConfig())) {
        self.httpClient = httpClient
    }
    
    func fetchFeed(pageToken: String?) async throws -> FeedAPIResponse {
        let endpoint = Endpoint(path: "/feed", method: .get)
        let response: FeedAPIResponse = try await httpClient.send(endpoint)
        return response
    }
    
    func fetchPostDetail(id: String) async throws -> PostDetailAPIResponse {
        let endpoint = Endpoint(path: "/posts/\(id)", method: .get)
        let response: PostDetailAPIResponse = try await httpClient.send(endpoint)
        return response
    }
    
    func createPost(_ request: NewPostRequest) async throws {
        // TODO: Impl.
    }
    
    func interact(_ request: PostInteractionRequest) async throws {
        // TODO: Impl.
    }
}
