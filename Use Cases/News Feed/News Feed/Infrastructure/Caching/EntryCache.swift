//
//  NSCache+Subscript.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/9/25.
//

import Foundation

// Concrete wrapper to avoid Objective-C generic extension specialization issues
final class EntryCache {
    private let storage = NSCache<NSString, CacheStateBox>()

    init(countLimit: Int = 0) {
        if countLimit > 0 { storage.countLimit = countLimit }
    }

    func get<T>(_ key: String, as type: T.Type) -> CacheState<T>? {
        storage.object(forKey: key as NSString)?.get(as: T.self)
    }

    func set<T>(_ key: String, entry: CacheState<T>?) {
        let nsKey = key as NSString
        if let entry {
            storage.setObject(CacheStateBox(entry), forKey: nsKey)
        } else {
            storage.removeObject(forKey: nsKey)
        }
    }

    func get<T>(url: URL, as type: T.Type) -> CacheState<T>? {
        get(url.absoluteString, as: T.self)
    }

    func set<T>(url: URL, entry: CacheState<T>?) {
        set(url.absoluteString, entry: entry)
    }
}
