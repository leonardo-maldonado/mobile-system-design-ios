import Foundation

struct OptimisticUpdate<T> {
    let original: T
    let updated: T
    
    init(original: T, updated: T) {
        self.original = original
        self.updated = updated
    }
    
    func commit() -> T { updated }
    func rollback() -> T { original }
}

struct PostInteractionResult {
    let postId: String
    let liked: Bool
    let likesCount: Int
    let error: Error?
    
    init(postId: String, liked: Bool, likesCount: Int, error: Error? = nil) {
        self.postId = postId
        self.liked = liked
        self.likesCount = likesCount
        self.error = error
    }
}

struct PostInteraction {
    let postId: String
    let action: UserInteraction.Action
    let optimisticUpdate: OptimisticUpdate<PostDetail>
    
    init(postId: String, action: UserInteraction.Action, original: PostDetail) {
        self.postId = postId
        self.action = action
        
        var updated = original
        switch action {
        case .like:
            updated.liked = true
            updated.likesCount += 1
        case .unlike:
            updated.liked = false
            updated.likesCount = max(0, updated.likesCount - 1)
        case .shared:
            updated.sharedCount += 1
        case .bookmarked:
            break
        }
        
        self.optimisticUpdate = OptimisticUpdate(original: original, updated: updated)
    }
    
    func execute(
        remoteDataSource: PostRemoteDataFetching,
        localDataSource: PostLocalDataStoring,
        cache: PostDetailCache
    ) async throws -> PostInteractionResult {
        await cache[id: postId] = .ready(optimisticUpdate.updated)
        
        let request = PostInteractionRequest(postId: postId, action: action.rawValue)
        
        // Execute both operations concurrently
        async let remoteTask = remoteDataSource.interact(request)
        async let localTask = localDataSource.interact(request)
        
        // Wait for both to complete and handle errors
        do {
            try await (remoteTask, localTask)
            
            return PostInteractionResult(
                postId: postId,
                liked: optimisticUpdate.updated.liked,
                likesCount: optimisticUpdate.updated.likesCount
            )
        } catch {
            // Check if remote succeeded but local failed
            do {
                _ = try await remoteTask
                // Remote succeeded, local failed - still consider it a success but report the error
                return PostInteractionResult(
                    postId: postId,
                    liked: optimisticUpdate.updated.liked,
                    likesCount: optimisticUpdate.updated.likesCount,
                    error: error
                )
            } catch {
                // Both failed - rollback cache
                await cache[id: postId] = .ready(optimisticUpdate.rollback())
                
                return PostInteractionResult(
                    postId: postId,
                    liked: optimisticUpdate.original.liked,
                    likesCount: optimisticUpdate.original.likesCount,
                    error: error
                )
            }
        }
    }
}
