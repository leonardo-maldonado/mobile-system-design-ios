import SwiftUI

struct ImageGalleryRouter {
        
    @ViewBuilder
    static func destination(for route: ImageGalleryRoute) -> some View {
        switch route {
        case .detail(let media):
            ImageDetailView(media: media)
        }
    }
        
    static func makeDetailView(for media: Media) -> some View {
        ImageDetailView(media: media)
    }
}

// MARK: - Route Definition

enum ImageGalleryRoute: Hashable {
    case detail(Media)
}
