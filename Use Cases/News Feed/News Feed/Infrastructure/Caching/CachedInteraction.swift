//
//  CachedInteraction.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/9/25.
//

import Foundation

actor InteractionCache {
    private let cache: EntryCache

    init(countLimit: Int = 500) {
        self.cache = EntryCache(countLimit: countLimit)
    }

    subscript(id id: String) -> CacheState<UserInteraction>? {
        get { cache.get(id, as: UserInteraction.self) }
        set { cache.set(id, entry: newValue) }
    }
}

