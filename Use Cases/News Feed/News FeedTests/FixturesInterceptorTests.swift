import XCTest
@testable import News_Feed

final class FixturesInterceptorTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var interceptor: FixturesInterceptor!
    private var mockBundle: MockBundle!
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        mockBundle = MockBundle()
        interceptor = FixturesInterceptor(bundle: mockBundle)
    }
    
    override func tearDown() {
        interceptor = nil
        mockBundle = nil
        super.tearDown()
    }
    
    // MARK: - Feed Request Tests
    
    func testAdapt_FeedRequest_AddsFixtureHeaders() async throws {
        // Given
        let url = URL(string: "https://api.example.com/feed")!
        let request = URLRequest(url: url)
        mockBundle.feedFixtureURL = URL(string: "file:///feed_fixture.json")!
        
        // When
        let adaptedRequest = try await interceptor.adapt(request)
        
        // Then
        XCTAssertEqual(adaptedRequest.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(adaptedRequest.value(forHTTPHeaderField: "X-Debug-Fixture"), "fixture:feed_fixture")
        XCTAssertEqual(adaptedRequest.value(forHTTPHeaderField: "X-Debug-Fixture-URL"), "file:///feed_fixture.json")
    }
    
    func testAdapt_FeedRequest_ReturnsOriginalWhenFixtureNotFound() async throws {
        // Given
        let url = URL(string: "https://api.example.com/feed")!
        let request = URLRequest(url: url)
        mockBundle.feedFixtureURL = nil
        
        // When
        let adaptedRequest = try await interceptor.adapt(request)
        
        // Then
        XCTAssertEqual(adaptedRequest.url, request.url)
        XCTAssertNil(adaptedRequest.value(forHTTPHeaderField: "X-Debug-Fixture"))
    }
    
    // MARK: - Post Detail Request Tests
    
    func testAdapt_PostDetailRequest_AddsFixtureHeaders() async throws {
        // Given
        let url = URL(string: "https://api.example.com/posts/p_1")!
        let request = URLRequest(url: url)
        mockBundle.postDetailFixtureURL = URL(string: "file:///post_detail_p_1.json")!
        
        // When
        let adaptedRequest = try await interceptor.adapt(request)
        
        // Then
        XCTAssertEqual(adaptedRequest.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(adaptedRequest.value(forHTTPHeaderField: "X-Debug-Fixture"), "fixture:post_detail_p_1")
        XCTAssertEqual(adaptedRequest.value(forHTTPHeaderField: "X-Debug-Fixture-URL"), "file:///post_detail_p_1.json")
    }
    
    func testAdapt_PostDetailRequest_ReturnsOriginalWhenFixtureNotFound() async throws {
        // Given
        let url = URL(string: "https://api.example.com/posts/p_1")!
        let request = URLRequest(url: url)
        mockBundle.postDetailFixtureURL = nil
        
        // When
        let adaptedRequest = try await interceptor.adapt(request)
        
        // Then
        XCTAssertEqual(adaptedRequest.url, request.url)
        XCTAssertNil(adaptedRequest.value(forHTTPHeaderField: "X-Debug-Fixture"))
    }
    
    func testAdapt_PostDetailRequest_ExtractsPostIdCorrectly() async throws {
        // Given
        let url = URL(string: "https://api.example.com/posts/p_123")!
        let request = URLRequest(url: url)
        mockBundle.postDetailFixtureURL = URL(string: "file:///post_detail_p_123.json")!
        
        // When
        let adaptedRequest = try await interceptor.adapt(request)
        
        // Then
        XCTAssertEqual(adaptedRequest.value(forHTTPHeaderField: "X-Debug-Fixture"), "fixture:post_detail_p_123")
    }
    
    // MARK: - Interaction Request Tests
    
    func testAdapt_InteractionRequest_AddsInteractionHeader() async throws {
        // Given
        let url = URL(string: "https://api.example.com/posts/p_1/interact")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // When
        let adaptedRequest = try await interceptor.adapt(request)
        
        // Then
        XCTAssertEqual(adaptedRequest.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(adaptedRequest.value(forHTTPHeaderField: "X-Debug-Fixture"), "interaction:p_1")
    }
    
    func testAdapt_InteractionRequest_ExtractsPostIdCorrectly() async throws {
        // Given
        let url = URL(string: "https://api.example.com/posts/p_456/interact")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // When
        let adaptedRequest = try await interceptor.adapt(request)
        
        // Then
        XCTAssertEqual(adaptedRequest.value(forHTTPHeaderField: "X-Debug-Fixture"), "interaction:p_456")
    }
    
    // MARK: - Non-Matching Request Tests
    
    func testAdapt_NonMatchingRequest_ReturnsOriginal() async throws {
        // Given
        let url = URL(string: "https://api.example.com/users/profile")!
        let request = URLRequest(url: url)
        
        // When
        let adaptedRequest = try await interceptor.adapt(request)
        
        // Then
        XCTAssertEqual(adaptedRequest.url, request.url)
        XCTAssertNil(adaptedRequest.value(forHTTPHeaderField: "X-Debug-Fixture"))
    }
    
    func testAdapt_RequestWithoutURL_ReturnsOriginal() async throws {
        // Given
        var request = URLRequest(url: URL(string: "https://api.example.com")!)
        request.url = nil
        
        // When
        let adaptedRequest = try await interceptor.adapt(request)
        
        // Then
        XCTAssertEqual(adaptedRequest.url, request.url)
        XCTAssertNil(adaptedRequest.value(forHTTPHeaderField: "X-Debug-Fixture"))
    }
    
    // MARK: - Request Type Detection Tests
    
    func testIsFeedRequest_ReturnsTrueForFeedPath() {
        // Given
        let url = URL(string: "https://api.example.com/feed")!
        
        // When
        let result = interceptor.isFeedRequest(url)
        
        // Then
        XCTAssertTrue(result)
    }
    
    func testIsFeedRequest_ReturnsFalseForNonFeedPath() {
        // Given
        let url = URL(string: "https://api.example.com/posts")!
        
        // When
        let result = interceptor.isFeedRequest(url)
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testIsPostDetailRequest_ReturnsTrueForPostDetailPath() {
        // Given
        let url = URL(string: "https://api.example.com/posts/p_1")!
        
        // When
        let result = interceptor.isPostDetailRequest(url)
        
        // Then
        XCTAssertTrue(result)
    }
    
    func testIsPostDetailRequest_ReturnsFalseForInteractionPath() {
        // Given
        let url = URL(string: "https://api.example.com/posts/p_1/interact")!
        
        // When
        let result = interceptor.isPostDetailRequest(url)
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testIsInteractionRequest_ReturnsTrueForInteractionPath() {
        // Given
        let url = URL(string: "https://api.example.com/posts/p_1/interact")!
        
        // When
        let result = interceptor.isInteractionRequest(url, method: "POST")
        
        // Then
        XCTAssertTrue(result)
    }
    
    func testIsInteractionRequest_ReturnsFalseForNonPostMethod() {
        // Given
        let url = URL(string: "https://api.example.com/posts/p_1/interact")!
        
        // When
        let result = interceptor.isInteractionRequest(url, method: "GET")
        
        // Then
        XCTAssertFalse(result)
    }
    
    // MARK: - Post ID Extraction Tests
    
    func testExtractPostId_ExtractsCorrectlyFromDetailPath() {
        // Given
        let url = URL(string: "https://api.example.com/posts/p_123")!
        
        // When
        let result = interceptor.extractPostId(from: url)
        
        // Then
        XCTAssertEqual(result, "p_123")
    }
    
    func testExtractPostId_ExtractsCorrectlyFromInteractionPath() {
        // Given
        let url = URL(string: "https://api.example.com/posts/p_456/interact")!
        
        // When
        let result = interceptor.extractPostId(from: url)
        
        // Then
        XCTAssertEqual(result, "p_456")
    }
    
    func testExtractPostId_ReturnsUnknownForInvalidPath() {
        // Given
        let url = URL(string: "https://api.example.com/posts")!
        
        // When
        let result = interceptor.extractPostId(from: url)
        
        // Then
        XCTAssertEqual(result, "unknown")
    }
    
    // MARK: - Interceptor Lifecycle Tests
    
    func testWillSend_DoesNothing() {
        // Given
        let request = URLRequest(url: URL(string: "https://api.example.com")!)
        
        // When & Then - Should not crash
        interceptor.willSend(request)
    }
    
    func testDidReceive_DoesNothing() {
        // Given
        let data = Data()
        let response = HTTPURLResponse(url: URL(string: "https://api.example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        
        // When & Then - Should not crash
        interceptor.didReceive(data: data, response: response)
    }
}

// MARK: - Mock Implementations

private class MockBundle: Bundle {
    var feedFixtureURL: URL?
    var postDetailFixtureURL: URL?
    
    override func url(forResource name: String?, withExtension ext: String?) -> URL? {
        if name == "feed_fixture" {
            return feedFixtureURL
        } else if name?.hasPrefix("post_detail_") == true {
            return postDetailFixtureURL
        }
        return nil
    }
}

// MARK: - Private Extension for Testing

extension FixturesInterceptor {
    func isFeedRequest(_ url: URL) -> Bool {
        url.path.contains("/feed")
    }
    
    func isPostDetailRequest(_ url: URL) -> Bool {
        url.path.contains("/posts/") && !url.path.contains("/interact")
    }
    
    func isInteractionRequest(_ url: URL, method: String?) -> Bool {
        method == "POST" && url.path.contains("/interact")
    }
    
    func extractPostId(from url: URL) -> String {
        let pathComponents = url.pathComponents
        guard let postsIndex = pathComponents.firstIndex(of: "posts"),
              postsIndex + 1 < pathComponents.count else {
            return "unknown"
        }
        return pathComponents[postsIndex + 1]
    }
}
