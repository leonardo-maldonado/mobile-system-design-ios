//
//  MediaURLProvider.swift
//  ImageGallery
//
//  Created by Leonardo Maldonado on 7/20/25.
//

import Foundation

protocol MediaURLProviderProtocol {
    func getImageURLs() -> [URL]
}

class MediaURLProvider: MediaURLProviderProtocol {
    func getImageURLs() -> [URL] {
        // In production, this would:
        // - Call an API to get image URLs
        // - Read from a configuration file
        // - Get from user's photo library
        // - etc.
        
        // For now, return empty array or implement real logic
        return []
    }
}

// MARK: - Test/Demo Implementation
#if DEBUG
class MockMediaURLProvider: MediaURLProviderProtocol {
    func getImageURLs() -> [URL] {
        let pinnedsUrls = (1...10).compactMap { 
            URL(string: "https://picsum.photos/200/200?random=\($0)") 
        }
        let recentsUrls = (1...1000).compactMap {
            URL(string: "https://picsum.photos/200/200?random=\($0)")
        }
        return pinnedsUrls + recentsUrls
    }
}
#endif 
