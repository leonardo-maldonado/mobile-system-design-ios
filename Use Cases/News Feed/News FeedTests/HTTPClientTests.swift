import Foundation
import Testing
@testable import News_Feed

@Suite("HTTPClient")
struct HTTPClientTests {

    @Test
    func testGET_decodesResponse() async throws {
        struct Item: Codable, Equatable { let id: Int; let name: String }
        let items = [Item(id: 1, name: "A"), Item(id: 2, name: "B")]
        let data = try JSONEncoder().encode(items)

        let base = URL(string: "https://example.com")!
        let response = HTTPURLResponse(url: base.appendingPathComponent("/items"), statusCode: 200, httpVersion: nil, headerFields: nil)!

        let (client, protocolType) = makeClient(baseURL: base)
        protocolType.requestHandler = { _ in (response, data) }

        let endpoint = Endpoint(path: "/items", method: .get)
        let decoded: [Item] = try await client.send(endpoint)
        #expect(decoded == items)
    }

    @Test
    func testPOST_encodesBodyAndDecodesResponse() async throws {
        struct Req: Codable { let value: String }
        struct Res: Codable, Equatable { let ok: Bool }
        let res = Res(ok: true)
        let resData = try JSONEncoder().encode(res)

        let base = URL(string: "https://example.com")!
        let httpResponse = HTTPURLResponse(url: base.appendingPathComponent("/submit"), statusCode: 201, httpVersion: nil, headerFields: nil)!

        let (client, protocolType) = makeClient(baseURL: base)

        var capturedBody: Data?
        protocolType.requestHandler = { request in
            capturedBody = request.httpBody
            return (httpResponse, resData)
        }

        let endpoint = Endpoint(path: "/submit", method: .post)
        let decoded: Res = try await client.send(endpoint, body: Req(value: "hello"))

        #expect(decoded == res)
        let sent = try #require(capturedBody)
        let sentJSON = try JSONSerialization.jsonObject(with: sent) as? [String: String]
        #expect(sentJSON?["value"] == "hello")
    }

    @Test
    func testNon2xx_returnsHTTPErrorRequestFailed() async {
        let base = URL(string: "https://example.com")!
        let httpResponse = HTTPURLResponse(url: base.appendingPathComponent("/error"), statusCode: 500, httpVersion: nil, headerFields: nil)!

        let (client, protocolType) = makeClient(baseURL: base)
        protocolType.requestHandler = { _ in (httpResponse, Data("oops".utf8)) }

        let endpoint = Endpoint(path: "/error", method: .get)

        do {
            let _: String = try await client.send(endpoint)
            Issue.record("Expected error to be thrown")
        } catch let HTTPError.requestFailed(status, data) {
            #expect(status == 500)
            #expect(String(data: data, encoding: .utf8) == "oops")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // MARK: - Helpers

    func makeClient(baseURL: URL) -> (URLSessionHTTPClient, MockURLProtocol.Type) {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        let httpConfig = HTTPClientConfig(baseURL: baseURL, isLoggingEnabled: false)
        return (URLSessionHTTPClient(config: httpConfig, session: session), MockURLProtocol.self)
    }
}

final class MockURLProtocol: URLProtocol {
    // Return tuple: (HTTPURLResponse, Data)
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data { client?.urlProtocol(self, didLoad: data) }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}


