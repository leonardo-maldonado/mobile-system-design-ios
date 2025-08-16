//
//  DetailHeaderView.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/9/25.
//

import SwiftUI

struct DetailHeaderView: View {
    let name: String
    let createdAt: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(name.prefix(1)))
                        .font(.headline)
                )
            
            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)
                Text(createdAt.timeAgo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    DetailHeaderView(
        name: "John Doe",
        createdAt: "2025-08-09T10:30:00Z"
    )
    .padding()
}
