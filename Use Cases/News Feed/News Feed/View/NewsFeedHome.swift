import SwiftUI

struct NewsFeedHome: View {
    private let repository: PostRepositoryFetching = Container.shared.resolve(PostRepositoryFetching.self)

    var body: some View {
        NewsFeedScreen(repository: repository)
            .navigationTitle("News Feed")
    }
}

#Preview {
    NewsFeedHome()
}

