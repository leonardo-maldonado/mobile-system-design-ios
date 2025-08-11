import Foundation

#if DEBUG
struct FixturesInterceptor: HTTPRequestInterceptor {
    // Keys are path fragments to match anywhere in the URL path
    var routes: [String: String] = [
        "feed": "feed_fixture",
        "posts": "post_detail_fixture"
    ]
    // Optional multiplier per route to expand array payloads (e.g., feed)
    var multipliers: [String: Int] = [
        "feed": 100
    ]
    let bundle: Bundle

    init(bundle: Bundle = .main, routes: [String: String] = [:], multipliers: [String: Int] = [:]) {
        self.bundle = bundle
        if !routes.isEmpty { self.routes = routes }
        if !multipliers.isEmpty { self.multipliers = multipliers }
    }

    func adapt(_ request: URLRequest) async throws -> URLRequest {
        guard
            let url = request.url,
            let fixtureName = routes.first(where: { key, _ in url.path.contains("/\(key)") || url.lastPathComponent == key })?.value,
            let fileURL = bundle.url(forResource: fixtureName, withExtension: "json")
        else {
            return request
        }

        var mutated = request
        mutated.setValue("application/json", forHTTPHeaderField: "Accept")
        mutated.setValue("fixture:\(fixtureName)", forHTTPHeaderField: "X-Debug-Fixture")
        mutated.setValue(fileURL.absoluteString, forHTTPHeaderField: "X-Debug-Fixture-URL")
        if let mult = multipliers.first(where: { key, _ in url.path.contains("/\(key)") || url.lastPathComponent == key })?.value, mult > 1 {
            mutated.setValue(String(mult), forHTTPHeaderField: "X-Debug-Fixture-Multiply")
        }
        return mutated
    }

    func willSend(_ request: URLRequest) {}
    func didReceive(data: Data, response: URLResponse) {}
}
#endif


