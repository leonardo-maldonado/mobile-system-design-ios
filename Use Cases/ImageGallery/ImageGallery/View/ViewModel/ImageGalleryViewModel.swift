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
    convenience init() {
        let remoteDataSource = MediaRemoteDataSource()
        let localDataSource = MediaLocalDataSource()
        
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
            return .success(media)
        case .failure(let error):
            return .failure(.repositoryError(error))
        }
    }
}

