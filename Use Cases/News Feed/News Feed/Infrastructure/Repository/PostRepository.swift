import Foundation
import Combine

protocol PostRepositoryFetching {
    func fetchPosts() async throws -> [PostPreview]
    func fetchPostDetail(id: String) async throws -> PostDetail
    func savePost(_ post: PostDetail) async throws
    func interactWithPost(_ postId: String, action: UserInteraction.Action) async throws
    func createPost(_ request: NewPostRequest) async throws
}

final class PostRepository: PostRepositoryFetching {

    private let remoteDataSource: PostRemoteDataFetching
    private let localDataSource: PostLocalDataStoring
    private let postPreviewCache: PostPreviewCache // For lightweight feed data
    private let postDetailCache: PostDetailCache   // For full detail data
    let interactionChanges = PassthroughSubject<PostInteractionChanged, Never>()
    
    init(
        remoteDataSource: PostRemoteDataFetching,
        localDataSource: PostLocalDataStoring,
        postPreviewCache: PostPreviewCache = PostPreviewCache(),
        postDetailCache: PostDetailCache = PostDetailCache(),
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
        self.postPreviewCache = postPreviewCache
        self.postDetailCache = postDetailCache
    }
    
    func fetchPosts() async throws -> [PostPreview] {
        // Try local cache/disk first
        if let local = try? await localDataSource.loadFeed(), !local.isEmpty {
            // Convert to PostPreview and cache them
            let previews = local.map { $0.toDomain() }
            for preview in previews {
                await postPreviewCache[id: preview.postId] = .ready(preview)
            }
            return previews
        }

        // Fallback to remote
        let response = try await remoteDataSource.fetchFeed(pageToken: nil)
        
        // Cache previews directly (no conversion needed)
        for preview in response.feed {
            await postPreviewCache[id: preview.postId] = .ready(preview)
        }
        
        return response.feed
    }
    
    func fetchPostDetail(id: String) async throws -> PostDetail {
        // Check detail cache first
        if let entry = await postDetailCache[id: id] {
            switch entry {
            case .ready(let value):
                return value
            case .inProgress(let task):
                return try await task.value
            }
        }

        // Check disk
        if let dao = try? await localDataSource.loadPost(id: id) {
            let detail = dao.toDomain()
            await postDetailCache[id: id] = .ready(detail)
            return detail
        }

        // Fetch from remote
        let task = Task<PostDetail, Error> {
            let remote = try await remoteDataSource.fetchPostDetail(id: id)
            return remote.post
        }
        await postDetailCache[id: id] = .inProgress(task)
        let result = try await task.value
        await postDetailCache[id: id] = .ready(result)
        return result
    }
    
    func savePost(_ post: PostDetail) async throws {
        await postDetailCache[id: post.id] = .ready(post)
        // try await localDataSource.upsertPost(...)
    }
    
    func interactWithPost(_ postId: String, action: UserInteraction.Action) async throws {
        // Get or create detail for interaction
        let detail = try await getOrCreateDetail(for: postId)
        
        // Create and execute the interaction
        let interaction = PostInteraction(postId: postId, action: action, original: detail)
        let result = try await interaction.execute(
            remoteDataSource: remoteDataSource,
            localDataSource: localDataSource,
            cache: postDetailCache
        )
        
        // Update cache with new state
        let updatedDetail = PostDetail(
            id: detail.id,
            content: detail.content,
            author: detail.author,
            createdAt: detail.createdAt,
            likesCount: result.likesCount,
            liked: result.liked,
            sharedCount: detail.sharedCount,
            attachments: detail.attachments
        )
        
        await postDetailCache[id: postId] = .ready(updatedDetail)
        
        // Publish interaction change
        let event = PostInteractionChanged(
            postId: postId,
            liked: result.liked,
            likeCount: result.likesCount
        )
        
        interactionChanges.send(event)
    }
    
    private func getOrCreateDetail(for postId: String) async throws -> PostDetail {
        // Try to get existing detail
        if let entry = await postDetailCache[id: postId], case .ready(let detail) = entry {
            return detail
        }
        
        // Try to get from preview cache and create minimal detail
        if let previewEntry = await postPreviewCache[id: postId], case .ready(let preview) = previewEntry {
            let detail = PostDetail(
                id: preview.postId,
                content: preview.contentSummary,
                author: AuthorPreview(id: "", name: preview.author, profileImageThumbnailURL: nil),
                createdAt: preview.createdAt,
                likesCount: preview.likeCount,
                liked: preview.liked,
                sharedCount: 0,
                attachments: []
            )
            await postDetailCache[id: postId] = .ready(detail)
            return detail
        }
        
        // Fetch full detail from remote
        return try await fetchPostDetail(id: postId)
    }
    
    private func updateBothCaches(postId: String, result: PostInteractionResult) async {
        // Update detail cache
        if let detailEntry = await postDetailCache[id: postId], case .ready(let detail) = detailEntry {
            let updatedDetail = PostDetail(
                id: detail.id,
                content: detail.content,
                author: detail.author,
                createdAt: detail.createdAt,
                likesCount: result.likesCount,
                liked: result.liked,
                sharedCount: detail.sharedCount,
                attachments: detail.attachments
            )
            await postDetailCache[id: postId] = .ready(updatedDetail)
        }
        
        // Update preview cache
        if let previewEntry = await postPreviewCache[id: postId], case .ready(let preview) = previewEntry {
            let updatedPreview = PostPreview(
                postId: preview.postId,
                contentSummary: preview.contentSummary,
                author: preview.author,
                createdAt: preview.createdAt,
                liked: result.liked,
                likeCount: result.likesCount, // Convert likesCount to likeCount
                attachtmentCount: preview.attachtmentCount,
                attachmentPreviewImageUrl: preview.attachmentPreviewImageUrl
            )
            await postPreviewCache[id: postId] = .ready(updatedPreview)
        }
    }

    func createPost(_ request: NewPostRequest) async throws {
        async let remote = remoteDataSource.createPost(request)
        async let local = localDataSource.createPost(request)
        _ = try await (remote, local)
    }
}