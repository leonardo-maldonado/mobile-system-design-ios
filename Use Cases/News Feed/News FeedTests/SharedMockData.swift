import Foundation
@testable import News_Feed

// MARK: - PostDetail Mock Extension

extension PostDetail {
    static var mock: PostDetail {
        PostDetail(
            id: "p_1",
            content: "Test content",
            author: AuthorPreview(id: "u_1", name: "Test Author", profileImageThumbnailURL: nil),
            createdAt: "2023-01-01T00:00:00Z",
            likesCount: 0,
            liked: false,
            sharedCount: 0,
            attachments: []
        )
    }
}

// MARK: - PostPreview Mock Extension

extension PostPreview {
    static var mock: PostPreview {
        PostPreview(
            postId: "p_2",
            contentSummary: "Test preview content",
            author: "Test Author",
            createdAt: "2023-01-01T00:00:00Z",
            liked: false,
            likeCount: 0,
            attachtmentCount: 0,
            attachmentPreviewImageUrl: nil
        )
    }
}

// MARK: - PostDAO Mock Extension

extension PostDAO {
    static var mock: PostDAO {
        PostDAO(
            id: "p_3",
            contentSummary: "Test content",
            author: "Test Author",
            createdAt: Date(),
            liked: false,
            likeCount: 0,
            attachmentCount: 0,
            attachmentPreviewImageUrl: nil
        )
    }
}

// MARK: - PostDetailDAO Mock Extension

extension PostDetailDAO {
    static var mock: PostDetailDAO {
        PostDetailDAO(
            id: "p_4",
            content: "Test content",
            authorId: "u_2",
            authorName: "Test Author",
            authorProfileImageThumbnailURL: nil,
            createdAt: Date(),
            likesCount: 0,
            liked: false,
            sharedCount: 0,
            attachments: []
        )
    }
}

// MARK: - NewPostRequest Mock Extension

extension NewPostRequest {
    static var mock: NewPostRequest {
        NewPostRequest(
            id: "p_5",
            content: "Test content",
            attachements: []
        )
    }
}

// MARK: - FeedAPIResponse Mock Extension

extension FeedAPIResponse {
    static var mock: FeedAPIResponse {
        FeedAPIResponse(
            feed: [PostPreview.mock],
            paging: PaginationMetaData(next: nil)
        )
    }
}

// MARK: - PostDetailAPIResponse Mock Extension

extension PostDetailAPIResponse {
    static var mock: PostDetailAPIResponse {
        PostDetailAPIResponse(post: PostDetail.mock)
    }
}


