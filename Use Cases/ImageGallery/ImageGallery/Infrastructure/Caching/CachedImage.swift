import Foundation
import SwiftData

@Model
final class CachedImage {
    @Attribute(.unique) var urlString: String
    var imageData: Data
    var timestamp: Date
    
    init(url: URL, imageData: Data) {
        self.urlString = url.absoluteString
        self.imageData = imageData
        self.timestamp = Date()
    }
    
    var url: URL? {
        URL(string: urlString)
    }
    
    var isExpired: Bool {
        // Cache expires after 7 days
        let expirationInterval: TimeInterval = 7 * 24 * 60 * 60
        return Date().timeIntervalSince(timestamp) > expirationInterval
    }
} 