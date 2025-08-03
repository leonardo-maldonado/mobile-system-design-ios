import SwiftUI

import SwiftUI

struct ImageGalleryView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ImageGalleryViewController {
        return ImageGalleryViewController()
    }
    
    func updateUIViewController(
        _ uiViewController: ImageGalleryViewController, context: Context) {
        // No dynamic update needed in this case
    }
}
