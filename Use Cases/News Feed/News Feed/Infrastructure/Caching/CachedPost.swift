//
//  CachedPost.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/9/25.
//

import Foundation

actor PostDetailCache {
    private let cache: EntryCache

    init(countLimit: Int = 200) {
        self.cache = EntryCache(countLimit: countLimit)
    }

    subscript(id id: String) -> CacheState<PostDetail>? {
        get { cache.get(id, as: PostDetail.self) }
        set { cache.set(id, entry: newValue) }
    }
}

