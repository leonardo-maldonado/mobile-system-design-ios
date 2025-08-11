//
//  News_FeedApp.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/8/25.
//

import SwiftUI

@main
struct News_FeedApp: App {
    var body: some Scene {
        WindowGroup {
            NewsFeedScreen(
                repository:
                    PostRepository(
                        remoteDataSource: {
                            #if DEBUG
                            let http = URLSessionHTTPClient(
                                config: HTTPClientConfig(),
                                interceptors: [FixturesInterceptor()]
                            )
                            return PostRemoteDataSource(httpClient: http)
                            #else
                            return PostRemoteDataSource()
                            #endif
                        }(),
                        localDataSource: PostLocalDataSource()
                    )
            )
        }
    }
}
