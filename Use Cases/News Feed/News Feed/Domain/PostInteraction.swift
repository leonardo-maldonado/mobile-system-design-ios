import Foundation

/// Represents an optimistic update that can be committed or rolled back
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

/// Result of a post interaction operation
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

/// Domain type representing a user interaction with a post
struct PostInteraction {
    let postId: String
    let action: UserInteraction.Action
    let optimisticUpdate: OptimisticUpdate<PostDetail>
    
    init(postId: String, action: UserInteraction.Action, original: PostDetail) {
        self.postId = postId
        self.action = action
        
        // Apply optimistic update based on action
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
            break // No optimistic update for bookmark
        }
        
        self.optimisticUpdate = OptimisticUpdate(original: original, updated: updated)
    }
    
    /// Execute the interaction with optimistic updates and error handling
    func execute(
        remoteDataSource: PostRemoteDataFetching,
        localDataSource: PostLocalDataStoring,
        cache: PostDetailCache
    ) async throws -> PostInteractionResult {
        // Apply optimistic update to cache
        await cache[id: postId] = .ready(optimisticUpdate.updated)
        
        do {
            // Execute remote and local persistence
            let request = PostInteractionRequest(id: postId, type: action.rawValue)
            async let remote = remoteDataSource.interact(request)
            async let local = localDataSource.interact(request)
            _ = try await (remote, local)
            
            // Success: return confirmed state
            return PostInteractionResult(
                postId: postId,
                liked: optimisticUpdate.updated.liked,
                likesCount: optimisticUpdate.updated.likesCount
            )
        } catch {
            // Failure: rollback optimistic update
            await cache[id: postId] = .ready(optimisticUpdate.rollback())
            
            // Return original state with error
            return PostInteractionResult(
                postId: postId,
                liked: optimisticUpdate.original.liked,
                likesCount: optimisticUpdate.original.likesCount,
                error: error
            )
        }
    }
}
