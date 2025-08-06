import SwiftUI

struct ImageGalleryView: UIViewControllerRepresentable {
    @ObservedObject var coordinator: ImageGalleryCoordinator
    
    func makeUIViewController(context: Context) -> ImageGalleryViewController {
        let controller = ImageGalleryViewController()
        controller.setInteractable(coordinator) // Connect UIKit to coordinator
        return controller
    }
    
    func updateUIViewController(
        _ uiViewController: ImageGalleryViewController, context: Context) {
        // No dynamic update needed in this case
    }
}
