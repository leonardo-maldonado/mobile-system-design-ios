import SwiftUI

struct RootView: View {
    @StateObject private var router: AppRouter
    private let repository: PostRepositoryFetching

    init(router: AppRouter, repository: PostRepositoryFetching) {
        _router = StateObject(wrappedValue: router)
        self.repository = repository
    }

    var body: some View {
        NavigationStack(path: binding(.feed)) {
            NewsFeedHome(repository: repository)
                .navigationDestination(for: AnyHashable.self) { route in
                    router.resolveDestination(for: route)
                }
        }
        .viewInteraction(router)
    }

    private func binding(_ tab: AppTab) -> Binding<[AnyHashable]> {
        Binding(
            get: { router.navigationStacks[tab] ?? [] },
            set: { router.navigationStacks[tab] = $0 }
        )
    }
}

