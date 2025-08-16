//
//  String+DateFormatting.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/9/25.
//

import Foundation

extension String {
    
    /// Converts an ISO 8601 date string to a relative time string
    /// - Returns: Relative time string (e.g., "2 hours ago", "1 day ago")
    var timeAgo: String {
        let iso = ISO8601DateFormatter()
        let rel = RelativeDateTimeFormatter()
        
        if let date = iso.date(from: self) {
            return rel.localizedString(for: date, relativeTo: Date())
        }
        return self
    }
}
