//
//  ImageDetailView.swift
//  ImageGallery
//
//  Created by Leonardo Maldonado on 8/5/25.
//
import SwiftUI

struct ImageDetailView: View {
    let media: Media
    var body: some View {
        if let data = media.data, let image = UIImage(data: data) {
            VStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
            .navigationTitle(media.url.lastPathComponent)
        } else {
            Text("No image data available")
                .navigationTitle(media.url.lastPathComponent)
        }
    }
}
