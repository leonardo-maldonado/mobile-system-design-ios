import SwiftUI

class Media: Identifiable, Hashable, @unchecked Sendable {
    typealias ID = UUID
    
    enum MediaType: Int {
        case pinned
        case recents
    }
    
    var id: ID
    var url: URL
    var data: Data? = nil
    var type: MediaType
    var accessibilityLabel: String
    
    init(id: ID = UUID(), url: URL, data: Data?, type: MediaType, accessibilityLabel: String) {
        self.id = id
        self.url = url
        self.data = data
        self.type = type
        self.accessibilityLabel = accessibilityLabel
    }
    
    static func == (lhs: Media, rhs: Media) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
