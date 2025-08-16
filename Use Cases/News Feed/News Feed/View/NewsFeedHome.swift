import SwiftUI

struct NewsFeedHome: View {
    private let repository: PostRepositoryFetching

    init(repository: PostRepositoryFetching) {
        self.repository = repository
    }

    var body: some View {
        NewsFeedScreen(repository: repository)
            .navigationTitle("News Feed")
    }
}

#Preview {
    let repo = Container.shared.resolve(PostRepositoryFetching.self)
    NewsFeedHome(repository: repo)
}

