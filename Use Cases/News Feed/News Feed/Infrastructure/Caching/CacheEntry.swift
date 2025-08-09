//
//  CacheEntry.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/9/25.
//

import Foundation

// A generic cache state that can represent either an in-flight task or a ready value
enum CacheState<Value> {
    case inProgress(Task<Value, Error>)
    case ready(Value)
}

// Type-erased wrapper to store generic CacheState values in NSCache (which requires AnyObject)
final class CacheStateBox: NSObject {
    private let boxed: Any
    private let valueType: Any.Type

    init<T>(_ entry: CacheState<T>) {
        self.boxed = entry
        self.valueType = T.self
    }

    func get<T>(as type: T.Type) -> CacheState<T>? {
        guard T.self == valueType, let typed = boxed as? CacheState<T> else { return nil }
        return typed
    }
}
