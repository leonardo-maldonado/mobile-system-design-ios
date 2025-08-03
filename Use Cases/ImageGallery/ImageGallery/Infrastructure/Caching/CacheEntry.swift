import Foundation

final class CacheEntryObject: NSObject {
    let entry: CacheEntry
    init(entry: CacheEntry) { self.entry = entry }
}

enum CacheEntry {
    case inProgress(Task<Media, Error>)
    case ready(Media)
}
