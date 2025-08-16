import Foundation

#if DEBUG
struct FixturesInterceptor: HTTPRequestInterceptor {
    private let bundle: Bundle
    
    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }
    
    func adapt(_ request: URLRequest) async throws -> URLRequest {
        guard let url = request.url else { return request }
        
        var mutated = request
        mutated.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Handle different request types
        if isFeedRequest(url) {
            return handleFeedRequest(mutated, url: url)
        } else if isPostDetailRequest(url) {
            return handlePostDetailRequest(mutated, url: url)
        } else if isInteractionRequest(url, method: request.httpMethod) {
            return handleInteractionRequest(mutated, url: url)
        }
        
        return request
    }
    
    func willSend(_ request: URLRequest) {}
    
    func didReceive(data: Data, response: URLResponse) {
        // No-op for this implementation
    }
}

// MARK: - Request Type Detection
private extension FixturesInterceptor {
    func isFeedRequest(_ url: URL) -> Bool {
        url.path.contains("/feed")
    }
    
    func isPostDetailRequest(_ url: URL) -> Bool {
        url.path.contains("/posts/") && !url.path.contains("/interact")
    }
    
    func isInteractionRequest(_ url: URL, method: String?) -> Bool {
        method == "POST" && url.path.contains("/interact")
    }
}

// MARK: - Request Handlers
private extension FixturesInterceptor {
    func handleFeedRequest(_ request: URLRequest, url: URL) -> URLRequest {
        var mutated = request
        guard let fixtureURL = bundle.url(forResource: "feed_fixture", withExtension: "json") else {
            return request
        }
        
        mutated.setValue(fixtureURL.absoluteString, forHTTPHeaderField: "X-Debug-Fixture-URL")
        mutated.setValue("fixture:feed_fixture", forHTTPHeaderField: "X-Debug-Fixture")
        return mutated
    }
    
    func handlePostDetailRequest(_ request: URLRequest, url: URL) -> URLRequest {
        var mutated = request
        let postId = extractPostId(from: url)
        let fixtureName = "post_detail_\(postId)"
        
        guard let fixtureURL = bundle.url(forResource: fixtureName, withExtension: "json") else {
            return request
        }
        
        mutated.setValue(fixtureURL.absoluteString, forHTTPHeaderField: "X-Debug-Fixture-URL")
        mutated.setValue("fixture:\(fixtureName)", forHTTPHeaderField: "X-Debug-Fixture")
        return mutated
    }
    
    func handleInteractionRequest(_ request: URLRequest, url: URL) -> URLRequest {
        var mutated = request
        let postId = extractPostId(from: url)
        mutated.setValue("interaction:\(postId)", forHTTPHeaderField: "X-Debug-Fixture")
        return mutated
    }
}

// MARK: - Utilities
private extension FixturesInterceptor {
    func extractPostId(from url: URL) -> String {
        // Extract post ID from URL path like "/posts/p_1" or "/posts/p_1/interact"
        let pathComponents = url.pathComponents
        guard let postsIndex = pathComponents.firstIndex(of: "posts"),
              postsIndex + 1 < pathComponents.count else {
            return "unknown"
        }
        return pathComponents[postsIndex + 1]
    }
}
#endif


