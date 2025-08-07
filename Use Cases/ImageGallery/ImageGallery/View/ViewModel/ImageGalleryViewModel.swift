import Foundation
import Combine

class ImageGalleryViewModel: ObservableObject {
    
    @Published var items: [Media] = []
    
    private let repository: MediaRepositoryProtocol
    
    enum ImageGalleryError: Error {
        case repositoryError(MediaError)
        case unknown
    }
    
    init(repository: MediaRepositoryProtocol) {
        self.repository = repository
    }
    
    // Convenience init with conditional URL provider
    @MainActor
    convenience init() {
        let remoteDataSource = MediaRemoteDataSource()
        
        let localDataSource = MediaLocalDataSource() // No modelContext parameter
        
        #if DEBUG
        let urlProvider = MockMediaURLProvider() // Demo URLs for development
        #else
        let urlProvider = MediaURLProvider()     
        #endif
        
        let repository = MediaRepository(
            remoteDataSource: remoteDataSource,
            localDataSource: localDataSource,
            urlProvider: urlProvider
        )
        self.init(repository: repository)
    }
    
    func loadAll() {
        items = repository.loadAllMedia()
    }
    
    nonisolated(nonsending)
    func prefetch(for item: Media) async -> Result<Media, ImageGalleryError> {
        let result = await repository.fetchImage(for: item)
        
        switch result {
        case .success(let media):
            // Update the source of truth
            await updateItem(with: media)
            return .success(media)
        case .failure(let error):
            return .failure(.repositoryError(error))
        }
    }
    
    // MARK: - Source of Truth Updates
    
    @MainActor
    private func updateItem(with loadedMedia: Media) {
        // Mutate existing instance so existing references (e.g., detail view) observe updated data
        if let index = items.firstIndex(where: { $0.id == loadedMedia.id }) {
            items[index].data = loadedMedia.data
        }
    }
    
    // Public method to get loaded media
    func getLoadedMedia(at index: Int) -> Media? {
        guard index < items.count else { return nil }
        return items[index]
    }
}

