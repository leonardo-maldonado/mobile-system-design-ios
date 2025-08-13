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
            let repo = Container.shared.resolve(PostRepositoryFetching.self)
            let router = AppRouter(modules: [
                AnyModuleRouter(FeedRouter(repository: repo)) { vi in
                    if case let .feed(i) = vi { return i } else { return nil }
                }
            ])
            RootView(router: router)
        }
    }
}
