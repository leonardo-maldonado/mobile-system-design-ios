import SwiftUI

struct AnyModuleRouter {
    private let _routeFor: (ViewInteraction) -> AnyHashable?
    private let _canHandle: (AnyHashable) -> Bool
    private let _destination: (AnyHashable) -> AnyView?
    private let _routeFromURL: (URL) -> AnyHashable?
    private let _tabFor: (AnyHashable) -> AppTab?

    init<R: ModuleRouter>(_ router: R, map: @escaping (ViewInteraction) -> R.Interaction?) {
        _routeFor = { vi in
            guard let i = map(vi) else { return nil }
            return router.handleInteraction(i).map(AnyHashable.init)
        }
        _canHandle = { route in route is R.Route }
        _destination = { route in
            guard let r = route as? R.Route else { return nil }
            return router.destination(for: r)
        }
        _routeFromURL = { url in router.route(from: url).map(AnyHashable.init) }
        _tabFor = { route in
            guard let r = route as? R.Route else { return nil }
            return router.tab(for: r)
        }
    }

    func route(for i: ViewInteraction) -> AnyHashable? { _routeFor(i) }
    func canHandle(route: AnyHashable) -> Bool { _canHandle(route) }
    func destination(for route: AnyHashable) -> AnyView? { _destination(route) }
    func route(from url: URL) -> AnyHashable? { _routeFromURL(url) }
    func tab(for route: AnyHashable) -> AppTab? { _tabFor(route) }
}

