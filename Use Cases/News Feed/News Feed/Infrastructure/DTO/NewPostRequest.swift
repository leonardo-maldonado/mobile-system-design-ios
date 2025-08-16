//
//  NewPostRequest.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/8/25.
//

struct NewPostRequest: Codable {
    var id: String
    var content: String
    var attachements: [PostAttachement]?
}
