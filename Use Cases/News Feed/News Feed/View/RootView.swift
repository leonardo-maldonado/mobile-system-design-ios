import SwiftUI

struct RootView: View {
    @StateObject private var router: AppRouter

    init(router: AppRouter) {
        _router = StateObject(wrappedValue: router)
    }

    var body: some View {
        NavigationStack(path: binding(.feed)) {
            NewsFeedHome()
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

