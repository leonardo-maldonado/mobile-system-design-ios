import SwiftUI

protocol ModuleRouter {
    associatedtype Route: Hashable
    associatedtype Interaction: Equatable

    func handleInteraction(_ interaction: Interaction) -> Route?
    func destination(for route: Route) -> AnyView?
    func route(from url: URL) -> Route?
    func tab(for route: Route) -> AppTab?
}

