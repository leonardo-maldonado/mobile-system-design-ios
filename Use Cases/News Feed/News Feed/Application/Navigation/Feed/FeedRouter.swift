import SwiftUI

enum FeedRoute: Hashable {
    case detail(String)
    case createPost
}

enum FeedInteraction: Equatable {
    case openDetail(String)
    case openCreatePost
}

struct FeedRouter: ModuleRouter {
    let repository: PostRepositoryFetching

    func handleInteraction(_ interaction: FeedInteraction) -> FeedRoute? {
        switch interaction {
        case .openDetail(let id): return .detail(id)
        case .openCreatePost: return .createPost
        }
    }

    func destination(for route: FeedRoute) -> AnyView? {
        switch route {
        case .detail(let id):
            AnyView(NewsFeedDetailScreen(repository: repository, postId: id))
        case .createPost:
            AnyView(CreatePostScreen(repository: repository))
        }
    }

    func route(from url: URL) -> FeedRoute? { nil }

    func tab(for route: FeedRoute) -> AppTab? { .feed }
}

