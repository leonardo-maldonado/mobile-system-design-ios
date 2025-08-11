import Foundation

enum AppContainer {
    static func configure() {
        // Shared HTTP client
        let http: URLSessionHTTPClient = {
            #if DEBUG
            URLSessionHTTPClient(
                config: HTTPClientConfig(isLoggingEnabled: false),
                interceptors: [FixturesInterceptor()]
            )
            #else
            URLSessionHTTPClient(config: HTTPClientConfig())
            #endif
        }()

        Container.shared.register(URLSessionHTTPClient.self) { http }
        Container.shared.register(PostRemoteDataFetching.self) {
            PostRemoteDataSource(httpClient: Container.shared.resolve(URLSessionHTTPClient.self))
        }
        Container.shared.register(PostLocalDataStoring.self) { PostLocalDataSource() }
        Container.shared.register(PostRepositoryFetching.self) {
            PostRepository(
                remoteDataSource: Container.shared.resolve(PostRemoteDataFetching.self),
                localDataSource: Container.shared.resolve(PostLocalDataStoring.self)
            )
        }
    }
}


