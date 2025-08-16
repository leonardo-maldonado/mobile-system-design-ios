import Foundation

struct PostInteractionChanged {
    let postId: String
    let liked: Bool
    let likeCount: Int
    let error: Error?
    
    init(postId: String, liked: Bool, likeCount: Int, error: Error? = nil) {
        self.postId = postId
        self.liked = liked
        self.likeCount = likeCount
        self.error = error
    }
}

