//
//  MediaLocalDataSource.swift
//  ImageGallery
//
//  Created by Leonardo Maldonado on 7/20/25.
//

import Foundation

protocol MediaLocalDataSourceProtocol {
    func getCachedMedia(for url: URL) -> CacheEntry?
    func setCachedMedia(_ entry: CacheEntry, for url: URL)
    func clearCache()
}

class MediaLocalDataSource: MediaLocalDataSourceProtocol {
    
    private let imageCache = NSCache<NSString, CacheEntryObject>()
    
    init() {
        imageCache.countLimit = 200
        imageCache.totalCostLimit = 100 * 1024 * 1024 // 100MB
    }
    
    func getCachedMedia(for url: URL) -> CacheEntry? {
        return imageCache[url]
    }
    
    func setCachedMedia(_ entry: CacheEntry, for url: URL) {
        imageCache[url] = entry
    }
    
    func clearCache() {
        imageCache.removeAllObjects()
    }
}

