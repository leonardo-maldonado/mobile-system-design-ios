import Foundation

final class Container {
    static let shared = Container()

    private var factories: [ObjectIdentifier: () -> Any] = [:]

    private init() {}

    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        factories[ObjectIdentifier(type)] = factory
    }

    func resolve<T>(_ type: T.Type) -> T {
        guard let service = factories[ObjectIdentifier(type)]?() as? T else {
            fatalError("No registration for \(type)")
        }
        return service
    }
}


