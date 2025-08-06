import Foundation
import Combine

class ImageGalleryCoordinator: ObservableObject, @MainActor ImageGalleryInteractable {
    
    @Published var currentRoute: ImageGalleryRoute?
    
    // MARK: - ImageGalleryInteractable (UIKit Bridge)
    
    func didSelectMedia(_ media: Media) {
        currentRoute = .detail(media)
    }
    
    // MARK: - Navigation Management
    
    func navigate(to route: ImageGalleryRoute) {
        currentRoute = route
    }
    
    func clearNavigation() {
        currentRoute = nil
    }
}
