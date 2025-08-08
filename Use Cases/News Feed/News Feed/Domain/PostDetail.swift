//
//  PostDetail.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/8/25.
//

struct PostDetail {
    var id: String
    var content: String
    var author: AuthorPreview
    var createdAt: String
    var likesCount: Int
    var liked: Bool
    var sharedCount: Int
    var attachments: [PostAttachement]
    
}
