import XCTest
@testable import News_Feed

final class PostInteractionTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var mockRemoteDataSource: MockPostRemoteDataSource!
    private var mockLocalDataSource: MockPostLocalDataSource!
    private var mockCache: PostDetailCache!
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        mockRemoteDataSource = MockPostRemoteDataSource()
        mockLocalDataSource = MockPostLocalDataSource()
        mockCache = PostDetailCache()
    }
    
    override func tearDown() {
        mockRemoteDataSource = nil
        mockLocalDataSource = nil
        mockCache = nil
        super.tearDown()
    }
    
    // MARK: - PostInteraction Initialization Tests
    
    func testPostInteraction_LikeAction() async {
        // Given
        let originalDetail = PostDetail.mock
        
        // When
        let interaction = await PostInteraction(postId: "p_1", action: .like, original: originalDetail)
        
        // Then
        await MainActor.run {
            XCTAssertEqual(interaction.postId, "p_1")
            XCTAssertEqual(interaction.action, UserInteraction.Action.like)
            XCTAssertEqual(interaction.optimisticUpdate.original.id, originalDetail.id)
            XCTAssertEqual(interaction.optimisticUpdate.updated.liked, true)
            XCTAssertEqual(interaction.optimisticUpdate.updated.likesCount, originalDetail.likesCount + 1)
        }
    }
    
    func testPostInteraction_UnlikeAction() async {
        // Given
        let originalDetail = PostDetail.mock
        
        // When
        let interaction = await PostInteraction(postId: "p_2", action: .unlike, original: originalDetail)
        
        // Then
        await MainActor.run {
            XCTAssertFalse(interaction.optimisticUpdate.updated.liked)
            XCTAssertEqual(interaction.optimisticUpdate.updated.likesCount, max(0, originalDetail.likesCount - 1))
        }
    }
    
    func testPostInteraction_UnlikeActionWhenAlreadyLiked() async {
        // Given
        var originalDetail = PostDetail.mock
        await MainActor.run {
            originalDetail.liked = true
            originalDetail.likesCount = 5
        }
        
        // When
        let interaction = await PostInteraction(postId: "p_3", action: .unlike, original: originalDetail)
        
        // Then
        await MainActor.run {
            XCTAssertFalse(interaction.optimisticUpdate.updated.liked)
            XCTAssertEqual(interaction.optimisticUpdate.updated.likesCount, 4)
        }
    }
    
    func testPostInteraction_UnlikeActionWhenNotLiked() async {
        // Given
        var originalDetail = PostDetail.mock
        await MainActor.run {
            originalDetail.liked = false
            originalDetail.likesCount = 0
        }
        
        // When
        let interaction = await PostInteraction(postId: "p_4", action: .unlike, original: originalDetail)
        
        // Then
        await MainActor.run {
            XCTAssertFalse(interaction.optimisticUpdate.updated.liked)
            XCTAssertEqual(interaction.optimisticUpdate.updated.likesCount, 0)
        }
    }
    
    func testPostInteraction_ShareAction() async {
        // Given
        let originalDetail = PostDetail.mock
        
        // When
        let interaction = await PostInteraction(postId: "p_5", action: .shared, original: originalDetail)
        
        // Then
        await MainActor.run {
            XCTAssertEqual(interaction.optimisticUpdate.updated.sharedCount, originalDetail.sharedCount + 1)
        }
    }
    
    func testPostInteraction_BookmarkAction() async {
        // Given
        let originalDetail = PostDetail.mock
        
        // When
        let interaction = await PostInteraction(postId: "p_6", action: .bookmarked, original: originalDetail)
        
        // Then
        await MainActor.run {
            XCTAssertEqual(interaction.optimisticUpdate.original.id, originalDetail.id)
            XCTAssertEqual(interaction.optimisticUpdate.updated.liked, originalDetail.liked)
            XCTAssertEqual(interaction.optimisticUpdate.updated.likesCount, originalDetail.likesCount)
            XCTAssertEqual(interaction.optimisticUpdate.updated.sharedCount, originalDetail.sharedCount)
        }
    }
    
    // MARK: - PostInteraction Execution Tests
    
    func testPostInteraction_ExecuteSuccess() async throws {
        // Given
        let originalDetail = PostDetail.mock
        let interaction = await PostInteraction(postId: "p_7", action: .like, original: originalDetail)
        mockRemoteDataSource.interactResult = ()
        mockLocalDataSource.interactResult = ()
        
        // When
        let result = try await interaction.execute(
            remoteDataSource: mockRemoteDataSource,
            localDataSource: mockLocalDataSource,
            cache: mockCache
        )
        
        // Then
        await MainActor.run {
            XCTAssertEqual(result.postId, "p_7")
            XCTAssertTrue(result.liked)
            XCTAssertEqual(result.likesCount, originalDetail.likesCount + 1)
            XCTAssertNil(result.error)
        }
        
        // Verify cache was updated
        let cachedState = await mockCache[id: "p_7"]
        if case .ready(let cachedDetail) = cachedState {
            XCTAssertTrue(cachedDetail.liked)
            XCTAssertEqual(cachedDetail.likesCount, originalDetail.likesCount + 1)
        } else {
            XCTFail("Expected cached detail to be ready")
        }
    }
    
    func testPostInteraction_ExecuteLocalFailure() async throws {
        // Given
        let originalDetail = PostDetail.mock
        let interaction = await PostInteraction(postId: "p_8", action: .like, original: originalDetail)
        mockRemoteDataSource.interactResult = ()
        mockLocalDataSource.interactError = NetworkError.serverError(500)
        
        // When
        let result = try await interaction.execute(
            remoteDataSource: mockRemoteDataSource,
            localDataSource: mockLocalDataSource,
            cache: mockCache
        )
        
        // Then
        await MainActor.run {
            XCTAssertEqual(result.postId, "p_8")
            XCTAssertTrue(result.liked)
            XCTAssertEqual(result.likesCount, originalDetail.likesCount + 1)
            XCTAssertNotNil(result.error) // Local failure should still be reported as error
        }
        
        // Verify cache was updated (not rolled back) since remote succeeded
        let cachedState = await mockCache[id: "p_8"]
        if case .ready(let cachedDetail) = cachedState {
            await MainActor.run {
                XCTAssertTrue(cachedDetail.liked)
                XCTAssertEqual(cachedDetail.likesCount, originalDetail.likesCount + 1)
            }
        } else {
            XCTFail("Expected cached detail to be ready")
        }
    }
    
    func testPostInteraction_ExecuteRemoteFailure() async throws {
        // Given
        let originalDetail = PostDetail.mock
        let interaction = await PostInteraction(postId: "p_9", action: .like, original: originalDetail)
        mockRemoteDataSource.interactError = NetworkError.serverError(500)
        mockLocalDataSource.interactError = NetworkError.serverError(500)
        
        // When
        let result = try await interaction.execute(
            remoteDataSource: mockRemoteDataSource,
            localDataSource: mockLocalDataSource,
            cache: mockCache
        )
        
        // Then
        await MainActor.run {
            XCTAssertEqual(result.postId, "p_9")
            XCTAssertEqual(result.liked, originalDetail.liked)
            XCTAssertEqual(result.likesCount, originalDetail.likesCount)
            XCTAssertNotNil(result.error)
        }
        
        // Verify cache was rolled back
        let cachedState = await mockCache[id: "p_9"]
        if case .ready(let cachedDetail) = cachedState {
            await MainActor.run {
                XCTAssertEqual(cachedDetail.liked, originalDetail.liked)
                XCTAssertEqual(cachedDetail.likesCount, originalDetail.likesCount)
            }
        } else {
            XCTFail("Expected cached detail to be ready")
        }
    }
    
    func testPostInteraction_ExecuteBothFailures() async throws {
        // Given
        let originalDetail = PostDetail.mock
        let interaction = await PostInteraction(postId: "p_10", action: .like, original: originalDetail)
        mockRemoteDataSource.interactError = NetworkError.serverError(500)
        mockLocalDataSource.interactError = NetworkError.serverError(500)
        
        // When
        let result = try await interaction.execute(
            remoteDataSource: mockRemoteDataSource,
            localDataSource: mockLocalDataSource,
            cache: mockCache
        )
        
        // Then
        await MainActor.run {
            XCTAssertEqual(result.postId, "p_10")
            XCTAssertEqual(result.liked, originalDetail.liked)
            XCTAssertEqual(result.likesCount, originalDetail.likesCount)
            XCTAssertNotNil(result.error)
        }
        
        // Verify cache was rolled back
        let cachedState = await mockCache[id: "p_10"]
        if case .ready(let cachedDetail) = cachedState {
            await MainActor.run {
                XCTAssertEqual(cachedDetail.liked, originalDetail.liked)
                XCTAssertEqual(cachedDetail.likesCount, originalDetail.likesCount)
            }
        } else {
            XCTFail("Expected cached detail to be ready")
        }
    }
    
    func testPostInteraction_ExecuteRemoteSuccessLocalFailure() async throws {
        // Given
        let originalDetail = PostDetail.mock
        let interaction = await PostInteraction(postId: "p_11", action: .like, original: originalDetail)
        mockRemoteDataSource.interactResult = ()
        mockLocalDataSource.interactError = NetworkError.serverError(500)
        
        // When
        let result = try await interaction.execute(
            remoteDataSource: mockRemoteDataSource,
            localDataSource: mockLocalDataSource,
            cache: mockCache
        )
        
        // Then
        await MainActor.run {
            XCTAssertEqual(result.postId, "p_11")
            XCTAssertTrue(result.liked)
            XCTAssertEqual(result.likesCount, originalDetail.likesCount + 1)
            XCTAssertNotNil(result.error) // Local failure should be reported as error
        }
        
        // Verify cache was updated (not rolled back) since remote succeeded
        let cachedState = await mockCache[id: "p_11"]
        if case .ready(let cachedDetail) = cachedState {
            await MainActor.run {
                XCTAssertTrue(cachedDetail.liked)
                XCTAssertEqual(cachedDetail.likesCount, originalDetail.likesCount + 1)
            }
        } else {
            XCTFail("Expected cached detail to be ready")
        }
    }
}

// MARK: - Mock Implementations

private class MockPostRemoteDataSource: PostRemoteDataFetching {
    var fetchFeedResult: FeedAPIResponse?
    var fetchFeedError: Error?
    var fetchFeedCalled = false
    
    var fetchPostDetailResult: PostDetailAPIResponse?
    var fetchPostDetailError: Error?
    var fetchPostDetailCalled = false
    
    var createPostResult: Void?
    var createPostError: Error?
    var createPostCalled = false
    
    var interactResult: Void?
    var interactError: Error?
    var interactCalled = false
    
    func fetchFeed(pageToken: String?) async throws -> FeedAPIResponse {
        fetchFeedCalled = true
        if let error = fetchFeedError { throw error }
        return fetchFeedResult ?? FeedAPIResponse(feed: [], paging: FeedAPIResponse.PaginationMetaData(next: nil))
    }
    
    func fetchPostDetail(id: String) async throws -> PostDetailAPIResponse {
        fetchPostDetailCalled = true
        if let error = fetchPostDetailError { throw error }
        return fetchPostDetailResult ?? PostDetailAPIResponse(post: PostDetail.mock)
    }
    
    func createPost(_ request: NewPostRequest) async throws {
        createPostCalled = true
        if let error = createPostError { throw error }
    }
    
    func interact(_ request: PostInteractionRequest) async throws {
        interactCalled = true
        if let error = interactError { throw error }
    }
}

private class MockPostLocalDataSource: PostLocalDataStoring {
    var loadFeedResult: [PostDAO]?
    var loadFeedError: Error?
    var loadFeedCalled = false
    
    var loadPostResult: PostDetailDAO?
    var loadPostError: Error?
    var loadPostCalled = false
    
    var saveFeedResult: Void?
    var saveFeedError: Error?
    var saveFeedCalled = false
    
    var createPostResult: Void?
    var createPostError: Error?
    var createPostCalled = false
    
    var interactResult: Void?
    var interactError: Error?
    var interactCalled = false
    
    func loadFeed() async throws -> [PostDAO] {
        loadFeedCalled = true
        if let error = loadFeedError { throw error }
        return loadFeedResult ?? []
    }
    
    func loadPost(id: String) async throws -> PostDetailDAO? {
        loadPostCalled = true
        if let error = loadPostError { throw error }
        return loadPostResult
    }
    
    func saveFeed(_ posts: [PostDAO]) async throws {
        saveFeedCalled = true
        if let error = saveFeedError { throw error }
    }
    
    func createPost(_ request: NewPostRequest) async throws {
        createPostCalled = true
        if let error = createPostError { throw error }
    }
    
    func interact(_ request: PostInteractionRequest) async throws {
        interactCalled = true
        if let error = interactError { throw error }
    }
}


