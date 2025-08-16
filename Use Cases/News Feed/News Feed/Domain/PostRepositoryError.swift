import Foundation

enum PostRepositoryError: LocalizedError {
    case postNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .postNotFound(let postId):
            return "Post with ID \(postId) not found"
        }
    }
}
