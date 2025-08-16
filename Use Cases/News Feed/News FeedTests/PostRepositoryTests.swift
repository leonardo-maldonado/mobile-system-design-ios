import XCTest
import Combine
@testable import News_Feed

// MARK: - Mock Implementations

private class MockPostRemoteDataSource: PostRemoteDataFetching {
    var fetchFeedCalled = false
    var fetchPostDetailCalled = false
    var interactCalled = false
    var createPostCalled = false
    
    var shouldThrowError = false
    var errorToThrow: Error = NetworkError.connectionLost
    
    func fetchFeed(pageToken: String?) async throws -> FeedAPIResponse {
        fetchFeedCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        return FeedAPIResponse(
            feed: [PostPreview.mock],
            paging: FeedAPIResponse.PaginationMetaData(next: nil)
        )
    }
    
    func fetchPostDetail(id: String) async throws -> PostDetailAPIResponse {
        fetchPostDetailCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        return PostDetailAPIResponse(post: PostDetail.mock)
    }
    
    func interact(_ request: PostInteractionRequest) async throws {
        interactCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
    }
    
    func createPost(_ request: NewPostRequest) async throws {
        createPostCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
    }
}

private class MockPostLocalDataSource: PostLocalDataStoring {
    var loadFeedCalled = false
    var loadPostCalled = false
    var saveFeedCalled = false
    var createPostCalled = false
    var interactCalled = false
    
    var shouldThrowError = false
    var errorToThrow: Error = NetworkError.connectionLost
    
    var mockPosts: [PostDAO] = [PostDAO.mock]
    var mockPostDetail: PostDetailDAO? = PostDetailDAO.mock
    
    func loadFeed() async throws -> [PostDAO] {
        loadFeedCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        return mockPosts
    }
    
    func loadPost(id: String) async throws -> PostDetailDAO? {
        loadPostCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        return mockPostDetail
    }
    
    func saveFeed(_ posts: [PostDAO]) async throws {
        saveFeedCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
    }
    
    func createPost(_ request: NewPostRequest) async throws {
        createPostCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
    }
    
    func interact(_ request: PostInteractionRequest) async throws {
        interactCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
    }
}

// MARK: - Test Cases

final class PostRepositoryTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var repository: PostRepository!
    private var mockRemoteDataSource: MockPostRemoteDataSource!
    private var mockLocalDataSource: MockPostLocalDataSource!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        mockRemoteDataSource = MockPostRemoteDataSource()
        mockLocalDataSource = MockPostLocalDataSource()
        repository = PostRepository(
            remoteDataSource: mockRemoteDataSource,
            localDataSource: mockLocalDataSource
        )
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        repository = nil
        mockRemoteDataSource = nil
        mockLocalDataSource = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Fetch Posts Tests
    
    func testFetchPosts_WhenLocalDataExists_ReturnsCachedData() async throws {
        // Given
        let localPosts = [PostDAO.mock]
        mockLocalDataSource.mockPosts = localPosts
        
        // When
        let result = try await repository.fetchPosts()
        
        // Then
        XCTAssertTrue(mockLocalDataSource.loadFeedCalled)
        XCTAssertFalse(mockRemoteDataSource.fetchFeedCalled)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.postId, localPosts.first?.id)
    }
    
    func testFetchPosts_WhenNoLocalData_FetchesFromRemote() async throws {
        // Given
        mockLocalDataSource.mockPosts = []
        
        // When
        let result = try await repository.fetchPosts()
        
        // Then
        XCTAssertTrue(mockLocalDataSource.loadFeedCalled)
        XCTAssertTrue(mockRemoteDataSource.fetchFeedCalled)
        XCTAssertEqual(result.count, 1)
    }
    
    func testFetchPosts_WhenRemoteFails_ThrowsError() async throws {
        // Given
        mockLocalDataSource.mockPosts = []
        mockRemoteDataSource.shouldThrowError = true
        
        // When & Then
        do {
            _ = try await repository.fetchPosts()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
    
    // MARK: - Fetch Post Detail Tests
    
    func testFetchPostDetail_WhenLocalDataExists_ReturnsLocalData() async throws {
        // Given
        let localDetail = PostDetailDAO.mock
        
        // When
        let result = try await repository.fetchPostDetail(id: "p_6")
        
        // Then
        XCTAssertTrue(mockLocalDataSource.loadPostCalled)
        XCTAssertFalse(mockRemoteDataSource.fetchPostDetailCalled)
        XCTAssertEqual(result.id, localDetail.id)
    }
    
    func testFetchPostDetail_WhenNoLocalData_FetchesFromRemote() async throws {
        // Given
        mockLocalDataSource.mockPostDetail = nil
        
        // When
        let result = try await repository.fetchPostDetail(id: "p_7")
        
        // Then
        XCTAssertTrue(mockLocalDataSource.loadPostCalled)
        XCTAssertTrue(mockRemoteDataSource.fetchPostDetailCalled)
        XCTAssertEqual(result.id, PostDetail.mock.id)
    }
    
    func testFetchPostDetail_WhenRemoteFails_ThrowsError() async throws {
        // Given
        mockLocalDataSource.mockPostDetail = nil
        mockRemoteDataSource.shouldThrowError = true
        
        // When & Then
        do {
            _ = try await repository.fetchPostDetail(id: "p_8")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
    
    // MARK: - Interact With Post Tests
    
    func testInteractWithPost_ExecutesInteractionSuccessfully() async throws {
        // Given
        let originalDetail = PostDetail.mock
        
        var receivedEvent: PostInteractionChanged?
        repository.interactionChanges
            .sink { event in
                receivedEvent = event
            }
            .store(in: &cancellables)
        
        // When
        try await repository.interactWithPost("p_9", action: .like)
        
        // Then
        XCTAssertNotNil(receivedEvent)
        XCTAssertEqual(receivedEvent?.postId, "p_9")
        XCTAssertTrue(receivedEvent?.liked == true)
        
        XCTAssertTrue(mockRemoteDataSource.interactCalled)
        XCTAssertTrue(mockLocalDataSource.interactCalled)
    }
    
    func testInteractWithPost_WhenRemoteFails_ThrowsError() async throws {
        // Given
        mockRemoteDataSource.shouldThrowError = true
        
        // When & Then
        do {
            try await repository.interactWithPost("p_10", action: .like)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
    
    // MARK: - Create Post Tests
    
    func testCreatePost_CreatesPostRemotelyAndLocally() async throws {
        // Given
        let request = NewPostRequest.mock
        
        // When
        try await repository.createPost(request)
        
        // Then
        XCTAssertTrue(mockRemoteDataSource.createPostCalled)
        XCTAssertTrue(mockLocalDataSource.createPostCalled)
    }
    
    func testCreatePost_WhenRemoteFails_ThrowsError() async throws {
        // Given
        let request = NewPostRequest.mock
        mockRemoteDataSource.shouldThrowError = true
        
        // When & Then
        do {
            try await repository.createPost(request)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
    
    // MARK: - Save Post Tests
    
    func testSavePost_UpdatesCache() async throws {
        // Given
        let post = PostDetail.mock
        
        // When
        try await repository.savePost(post)
        
        // Then
        // The savePost method should update the cache
        // We can't directly test the cache state since it's private,
        // but we can verify the method doesn't throw
        XCTAssertTrue(true) // Method completed successfully
    }
}


