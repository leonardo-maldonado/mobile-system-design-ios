//
//  News_FeedApp.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/8/25.
//

import SwiftUI

@main
struct News_FeedApp: App {
    init() {
        AppContainer.configure()
    }
    var body: some Scene {
        WindowGroup {
            NewsFeedScreen(repository: Container.shared.resolve(PostRepositoryFetching.self))
        }
    }
}
