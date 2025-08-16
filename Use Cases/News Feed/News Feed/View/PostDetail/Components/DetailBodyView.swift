//
//  DetailBodyView.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/9/25.
//

import SwiftUI

struct DetailBodyView: View {
    let content: String
    let firstAttachmentURL: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(content)
                .font(.body)
                .multilineTextAlignment(.leading)
            
            if let urlString = firstAttachmentURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 240)
                            .redacted(reason: .placeholder)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 240)
                            .clipped()
                            .cornerRadius(10)
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 240)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
    }
}

#Preview {
    DetailBodyView(
        content: "This is a sample post content that demonstrates how the DetailBodyView component works with text and optional images.",
        firstAttachmentURL: nil
    )
    .padding()
}
