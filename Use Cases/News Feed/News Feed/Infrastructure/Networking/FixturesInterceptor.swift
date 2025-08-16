import Foundation

#if DEBUG
struct FixturesInterceptor: HTTPRequestInterceptor {
    // Keys are path fragments to match anywhere in the URL path
    var routes: [String: String] = [
        "feed": "feed_fixture",
        "posts": "posts"
    ]
    var multipliers: [String: Int] = [:]
    let bundle: Bundle

    init(bundle: Bundle = .main, routes: [String: String] = [:], multipliers: [String: Int] = [:]) {
        self.bundle = bundle
        if !routes.isEmpty { self.routes = routes }
        if !multipliers.isEmpty { self.multipliers = multipliers }
    }

    func adapt(_ request: URLRequest) async throws -> URLRequest {
        guard
            let url = request.url,
            let routeMatch = routes.first(where: { key, _ in url.path.contains("/\(key)") || url.lastPathComponent == key })
        else {
            return request
        }

        var mutated = request
        mutated.setValue("application/json", forHTTPHeaderField: "Accept")

        // Resolve file URL. For posts, prefer per-id fixtures: /posts/{id} -> post_detail_{id}.json
        let fixtureName: String
        if routeMatch.key == "posts" {
            let id = url.lastPathComponent == "posts" ? nil : url.lastPathComponent
            if let id {
                let perId = "post_detail_\(id)"
                if let url = bundle.url(forResource: perId, withExtension: "json") {
                    fixtureName = perId
                    mutated.setValue(url.absoluteString, forHTTPHeaderField: "X-Debug-Fixture-URL")
                } else {
                    return request
                }
            } else {
                return request
            }
        } else {
            fixtureName = routeMatch.value
            guard let url = bundle.url(forResource: fixtureName, withExtension: "json") else { return request }
            mutated.setValue(url.absoluteString, forHTTPHeaderField: "X-Debug-Fixture-URL")
        }

        mutated.setValue("fixture:\(fixtureName)", forHTTPHeaderField: "X-Debug-Fixture")
        if let mult = multipliers.first(where: { key, _ in url.path.contains("/\(key)") || url.lastPathComponent == key })?.value, mult > 1 {
            mutated.setValue(String(mult), forHTTPHeaderField: "X-Debug-Fixture-Multiply")
        }
        return mutated
    }

    func willSend(_ request: URLRequest) {}
    func didReceive(data: Data, response: URLResponse) {}
}
#endif


