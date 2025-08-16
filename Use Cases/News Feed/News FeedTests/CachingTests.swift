import XCTest
@testable import News_Feed

final class CachingTests: XCTestCase {
    
    // MARK: - EntryCache Tests
    
    func testSetAndGet_ReadyState() async {
        // Given
        let detail = PostDetail.mock
        let cache = await MainActor.run { EntryCache(countLimit: 10) }
        
        // When
        await cache.set("p_25", entry: .ready(detail))
        let result = await cache.get("p_25", as: PostDetail.self)
        
        // Then
        if case .ready(let cachedDetail) = result {
            await MainActor.run {
                XCTAssertEqual(cachedDetail.id, detail.id)
                XCTAssertEqual(cachedDetail.content, detail.content)
            }
        } else {
            XCTFail("Expected ready state")
        }
    }
    
    func testSetAndGet_InProgressState() async {
        // Given
        let task = Task<PostDetail, Error> { PostDetail.mock }
        let cache = await MainActor.run { EntryCache(countLimit: 10) }
        
        // When
        await cache.set("p_26", entry: .inProgress(task))
        let result = await cache.get("p_26", as: PostDetail.self)
        
        // Then
        if case .inProgress = result {
            // Success - in progress state
        } else {
            XCTFail("Expected in progress state")
        }
    }
    
    func testSetAndGet_NilEntry() async {
        // Given
        let cache = await MainActor.run { EntryCache(countLimit: 10) }
        
        // When
        let result = await cache.get("p_27", as: PostDetail.self)
        
        // Then
        XCTAssertNil(result)
    }
    
    func testUpdateEntry_ReadyToReady() async {
        // Given
        let detail1 = PostDetail.mock
        let detail2 = PostDetail.mock
        let cache = await MainActor.run { EntryCache(countLimit: 10) }
        
        // When
        await cache.set("p_28", entry: .ready(detail1))
        await cache.set("p_28", entry: .ready(detail2))
        let result = await cache.get("p_28", as: PostDetail.self)
        
        // Then
        if case .ready(let cachedDetail) = result {
            await MainActor.run {
                XCTAssertEqual(cachedDetail.id, detail2.id)
            }
        } else {
            XCTFail("Expected ready state")
        }
    }
    
    func testUpdateEntry_InProgressToReady() async {
        // Given
        let task = Task<PostDetail, Error> { PostDetail.mock }
        let detail = PostDetail.mock
        let cache = await MainActor.run { EntryCache(countLimit: 10) }
        
        // When
        await cache.set("p_29", entry: .inProgress(task))
        await cache.set("p_29", entry: .ready(detail))
        let result = await cache.get("p_29", as: PostDetail.self)
        
        // Then
        if case .ready(let cachedDetail) = result {
            await MainActor.run {
                XCTAssertEqual(cachedDetail.id, detail.id)
            }
        } else {
            XCTFail("Expected ready state")
        }
    }
    
    func testUpdateEntry_ReadyToInProgress() async {
        // Given
        let detail = PostDetail.mock
        let task = Task<PostDetail, Error> { PostDetail.mock }
        let cache = await MainActor.run { EntryCache(countLimit: 10) }
        
        // When
        await cache.set("p_30", entry: .ready(detail))
        await cache.set("p_30", entry: .inProgress(task))
        let result = await cache.get("p_30", as: PostDetail.self)
        
        // Then
        if case .inProgress = result {
            // Success - in progress state
        } else {
            XCTFail("Expected in progress state")
        }
    }
    
    func testCacheEviction_WhenLimitReached() async {
        // Given
        let cache = await MainActor.run { EntryCache(countLimit: 2) }
        let detail1 = PostDetail.mock
        let detail2 = PostDetail.mock
        let detail3 = PostDetail.mock
        
        // When
        await cache.set("p_31", entry: .ready(detail1))
        await cache.set("p_32", entry: .ready(detail2))
        await cache.set("p_33", entry: .ready(detail3))
        
        let result1 = await cache.get("p_31", as: PostDetail.self)
        let result2 = await cache.get("p_32", as: PostDetail.self)
        let result3 = await cache.get("p_33", as: PostDetail.self)
        
        // Then
        XCTAssertNil(result1) // Should be evicted
        XCTAssertNotNil(result2)
        XCTAssertNotNil(result3)
    }
    
    func testCacheTypeSafety() async {
        // Given
        let cache = await MainActor.run { EntryCache(countLimit: 10) }
        let detail = PostDetail.mock
        let preview = PostPreview.mock
        
        // When
        await cache.set("detail-id", entry: .ready(detail))
        await cache.set("preview-id", entry: .ready(preview))
        
        let detailResult = await cache.get("detail-id", as: PostDetail.self)
        let previewResult = await cache.get("preview-id", as: PostPreview.self)
        let wrongTypeResult = await cache.get("detail-id", as: PostPreview.self)
        
        // Then
        XCTAssertNotNil(detailResult)
        XCTAssertNotNil(previewResult)
        XCTAssertNil(wrongTypeResult) // Type mismatch should return nil
    }
    
    func testCacheURLMethods() async {
        // Given
        let cache = await MainActor.run { EntryCache(countLimit: 10) }
        let detail = PostDetail.mock
        let url = URL(string: "https://example.com/post/p_34")!
        
        // When
        await cache.set(url: url, entry: .ready(detail))
        let result = await cache.get(url: url, as: PostDetail.self)
        
        // Then
        if case .ready(let cachedDetail) = result {
            await MainActor.run {
                XCTAssertEqual(cachedDetail.id, detail.id)
            }
        } else {
            XCTFail("Expected ready state")
        }
    }
    
    func testCacheRemoveEntry() async {
        // Given
        let cache = await MainActor.run { EntryCache(countLimit: 10) }
        let detail = PostDetail.mock
        
        // When
        await cache.set("p_35", entry: .ready(detail))
        let beforeRemove = await cache.get("p_35", as: PostDetail.self)
        await cache.set("p_35", entry: nil as CacheState<PostDetail>?)
        let afterRemove = await cache.get("p_35", as: PostDetail.self)
        
        // Then
        XCTAssertNotNil(beforeRemove)
        XCTAssertNil(afterRemove)
    }
}


