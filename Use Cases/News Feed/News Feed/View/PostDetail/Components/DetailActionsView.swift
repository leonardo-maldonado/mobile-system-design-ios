//
//  DetailActionsView.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/9/25.
//

import SwiftUI

struct DetailActionsView: View {
    let liked: Bool
    let likes: Int
    let shares: Int
    let onLike: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: onLike) {
                Label("\(likes)", systemImage: liked ? "heart.fill" : "heart")
                    .foregroundStyle(liked ? .red : .primary)
            }
            .buttonStyle(.bordered)
            
            Label("\(shares)", systemImage: "arrowshape.turn.up.right")
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }
}

#Preview {
    DetailActionsView(
        liked: false,
        likes: 42,
        shares: 5,
        onLike: {}
    )
    .padding()
}
