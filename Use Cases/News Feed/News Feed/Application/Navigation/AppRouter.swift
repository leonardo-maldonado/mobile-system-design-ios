import SwiftUI
import Combine

@MainActor
final class AppRouter: ObservableObject, ViewInteractable {
    @Published var selectedTab: AppTab = .feed
    @Published var navigationStacks: [AppTab: [AnyHashable]] = [:]

    private let modules: [AnyModuleRouter]

    init(modules: [AnyModuleRouter]) {
        self.modules = modules
    }

    func send(_ interaction: ViewInteraction) {
        guard let (route, module) = firstResolvedRoute(for: interaction) else { return }

        let tab = module.tab(for: route) ?? selectedTab
        var stack = navigationStacks[tab] ?? []
        
        stack.append(route)
        navigationStacks[tab] = stack
        selectedTab = tab
    }

    func resolveDestination(for route: AnyHashable) -> AnyView {
        for m in modules {
            if let v = m.destination(for: route) { return v }
        }
        return AnyView(EmptyView())
    }

    func route(from url: URL) -> AnyHashable? {
        for m in modules {
            if let r = m.route(from: url) { return r }
        }
        return nil
    }

    private func firstResolvedRoute(for interaction: ViewInteraction) -> (AnyHashable, AnyModuleRouter)? {
        for m in modules {
            if let r = m.route(for: interaction) { return (r, m) }
        }
        return nil
    }
}

