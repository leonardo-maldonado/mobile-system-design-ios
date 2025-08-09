//
//  PostRepository.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/8/25.
//

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
    private let postDetailCache: PostDetailCache
    
    init(
        remoteDataSource: PostRemoteDataFetching,
        localDataSource: PostLocalDataStoring,
        postDetailCache: PostDetailCache = PostDetailCache()
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
        self.postDetailCache = postDetailCache
    }
    
    func fetchPosts() async throws -> [PostPreview] {
        // Try local cache/disk first
        if let local = try? await localDataSource.loadFeed(), !local.isEmpty {
            return local.map { dao in
                // TODO: Map PostDAO -> PostPreview when DAO is defined
                PostPreview(
                    postId: "",
                    contentSummary: "",
                    author: "",
                    createdAt: "",
                    liked: false,
                    likeCount: 0,
                    attachtmentCount: 0,
                    attachmentPreviewImageUrl: nil
                )
            }
        }

        // Fallback to remote
        let response = try await remoteDataSource.fetchFeed(pageToken: nil)
        return response.feed
    }
    
    func fetchPostDetail(id: String) async throws -> PostDetail {
        // Memory cache
        if let entry = await postDetailCache[id: id] {
            switch entry {
            case .ready(let value):
                return value
            case .inProgress(let task):
                return try await task.value
            }
        }

        // Disk
        if let dao = try? await localDataSource.loadPost(id: id) {
            // TODO: Map PostDetailDAO -> PostDetail when DAO is defined
            let detail = PostDetail(
                id: id,
                content: "",
                author: AuthorPreview(id: "", name: "", profileImageThumbnailURL: nil),
                createdAt: "",
                likesCount: 0,
                liked: false,
                sharedCount: 0,
                attachments: []
            )
            await postDetailCache[id: id] = .ready(detail)
            return detail
        }

        // Remote
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
        // Persist locally and update memory cache
        // TODO: Map PostDetail -> PostDetailDAO when DAO is defined
        await postDetailCache[id: post.id] = .ready(post)
        // try await localDataSource.upsertPost(...)
    }
    
    func interactWithPost(_ postId: String, action: UserInteraction.Action) async throws {
        let request = PostInteractionRequest(id: postId, type: action.rawValue)
        // Optimistic update in memory cache if available
        if let entry = await postDetailCache[id: postId], case .ready(var detail) = entry {
            switch action {
            case .like:
                detail.liked = true
                detail.likesCount += 1
            case .unlike:
                detail.liked = false
                detail.likesCount = max(0, detail.likesCount - 1)
            case .shared:
                detail.sharedCount += 1
            case .bookmarked:
                break
            }
            await postDetailCache[id: postId] = .ready(detail)
        }

        // Fire and forget remote + local persistence
        async let remote = remoteDataSource.interact(request)
        async let local = localDataSource.interact(request)
        _ = try await (remote, local)
    }

    func createPost(_ request: NewPostRequest) async throws {
        async let remote = remoteDataSource.createPost(request)
        async let local = localDataSource.createPost(request)
        _ = try await (remote, local)
    }
}
