//
//  MediaLocalDataSource.swift
//  ImageGallery
//
//  Created by Leonardo Maldonado on 7/20/25.
//

import Foundation
import SwiftData

protocol MediaLocalDataSourceProtocol: Sendable {
    func getCachedMedia(for url: URL) async -> CacheEntry?
    func getCachedMediaFromDisk(for url: URL) async -> CacheEntry?
    func setCachedMedia(_ entry: CacheEntry, for url: URL) async
    func clearCache() async
}


actor MediaLocalDataSource: MediaLocalDataSourceProtocol {
    
    private let imageCache = NSCache<NSString, CacheEntryObject>()
    private let modelContext: ModelContext
    
    init() {
        let container = try! ModelContainer(for: CachedImage.self)
        self.modelContext = ModelContext(container)
        
        imageCache.countLimit = 200
        imageCache.totalCostLimit = 100 * 1024 * 1024 // 100MB
        
        Task.detached(priority: .background) {
            await self.clearExpiredCache()
        }
    }
    
    func getCachedMedia(for url: URL) async -> CacheEntry? {
        if let cachedObject = imageCache[url] {
            print("Found image in memory cache for URL: \(url)")
            return cachedObject
        }
        
        print("No image in memory cache for URL: \(url)")
        // For disk cache, we'll return nil immediately and let the repository handle async loading
        // This prevents blocking the main thread during scrolling
        return nil
    }
    
    func setCachedMedia(_ entry: CacheEntry, for url: URL) async {
        imageCache[url] = entry
        print("Cached image in memory for URL: \(url)")
        
        if case .ready(let media) = entry, let data = media.data {
            print("Saving image to disk for URL: \(url)")
            Task.detached(priority: .background) {
                await self.saveToDisk(url: url, data: data)
            }
        }
    }
    
    func clearCache() async {
        imageCache.removeAllObjects()
        Task.detached(priority: .background) {
            await self.clearDiskCache()
        }
    }
    
    // MARK: - Async Methods for Background Operations
    
    func getCachedMediaFromDisk(for url: URL) async -> CacheEntry? {
        if let cachedObject = imageCache[url] {
            print("Found image in memory cache for URL: \(url)")
            return cachedObject
        }
        
        print("Checking disk cache for URL: \(url)")
        let result = await checkOnDisk(for: url)
        
        if let entry = result {
            imageCache[url] = entry
            print("Updated memory cache with disk data for URL: \(url)")
        } else {
            print("No disk cache found for URL: \(url)")
        }
        
        return result
    }
    
    // MARK: - Private Static Methods (Safe for Task.detached)
    
    private func checkOnDisk(for url: URL) async -> CacheEntry? {
        let expirationDate = getExpirationDate()
        
        let descriptor = FetchDescriptor<CachedImage>(
            predicate: #Predicate<CachedImage> { cachedImage in
                cachedImage.urlString == url.absoluteString && cachedImage.timestamp >= expirationDate
            }
        )
        
        do {
            let cachedItems = try modelContext.fetch(descriptor)
            guard let cachedItem = cachedItems.first else { 
                print("No cached image found for URL: \(url)")
                return nil 
            }
            
            let media = Media(
                url: url,
                data: cachedItem.imageData,
                type: .recents, // Repository will override with original type
                accessibilityLabel: "Cached image"
            )
            
            print("Successfully loaded image from disk cache for URL: \(url)")
            return CacheEntry.ready(media)
        } catch {
            print("Failed to fetch from disk cache: \(error)")
            return nil
        }
    }
    
    private func saveToDisk(url: URL, data: Data) async {
        let cachedImage = CachedImage(url: url, imageData: data)
        modelContext.insert(cachedImage)
        
        do {
            try modelContext.save()
            print("Successfully saved image to disk for URL: \(url)")
        } catch {
            print("Failed to save to disk cache: \(error)")
        }
    }
    
    private func clearExpiredCache() async {
        let expirationDate = getExpirationDate()
        
        let descriptor = FetchDescriptor<CachedImage>(
            predicate: #Predicate<CachedImage> { cachedImage in
                cachedImage.timestamp < expirationDate
            }
        )
        
        do {
            let expiredItems = try modelContext.fetch(descriptor)
            for item in expiredItems {
                modelContext.delete(item)
            }
            try modelContext.save()
            print("Cleared \(expiredItems.count) expired cache items")
        } catch {
            print("Failed to clear expired cache: \(error)")
        }
    }
    
    private func clearDiskCache() async {
        let descriptor = FetchDescriptor<CachedImage>()
        
        do {
            let allItems = try modelContext.fetch(descriptor)
            for item in allItems {
                modelContext.delete(item)
            }
            try modelContext.save()
            print("Cleared all disk cache items")
        } catch {
            print("Failed to clear disk cache: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func getExpirationDate() -> Date {
        // Cache expires after 7 days
        let expirationInterval: TimeInterval = 7 * 24 * 60 * 60
        return Date().addingTimeInterval(-expirationInterval)
    }
}
