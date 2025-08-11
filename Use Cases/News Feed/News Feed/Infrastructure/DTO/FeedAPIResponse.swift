//
//  FeedAPIResponse.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/8/25.
//

struct FeedAPIResponse: Decodable {
    var feed: [PostPreview]
    var paging: PaginationMetaData
    
    
    struct PaginationMetaData: Decodable {
        var next: String?
    }
}
