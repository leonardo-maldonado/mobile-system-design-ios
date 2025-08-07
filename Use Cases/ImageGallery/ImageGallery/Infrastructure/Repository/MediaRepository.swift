//
//  MediaRepository.swift
//  ImageGallery
//
//  Created by Leonardo Maldonado on 7/20/25.
//

import Foundation

protocol MediaRepositoryProtocol: Sendable {
    func loadAllMedia() -> [Media]
    func fetchImage(for media: Media) async -> Result<Media, MediaError>
}

enum MediaError: Error {
    case networkError(Error)
    case cacheError
    case unknown
}

final class MediaRepository: MediaRepositoryProtocol {
    
    private let remoteDataSource: MediaRemoteDataSourceProtocol
    private let localDataSource: MediaLocalDataSourceProtocol
    private let urlProvider: MediaURLProviderProtocol
    
    init(
        remoteDataSource: MediaRemoteDataSourceProtocol,
        localDataSource: MediaLocalDataSourceProtocol,
        urlProvider: MediaURLProviderProtocol
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
        self.urlProvider = urlProvider
    }
    
    func loadAllMedia() -> [Media] {
        let urls = urlProvider.getImageURLs()
        
        let pinnedItems: [Media] = urls.prefix(10).map {
            Media(url: $0, data: nil, type: .pinned, accessibilityLabel: "")
        }
        
        let recentsItems: [Media] = urls.dropFirst(10).map {
            Media(url: $0, data: nil, type: .recents, accessibilityLabel: "")
        }
        
        return pinnedItems + recentsItems
    }
    
    func fetchImage(for media: Media) async -> Result<Media, MediaError> {
        if let cached = await localDataSource.getCachedMedia(for: media.url) {
            switch cached {
            case .ready(let cachedMedia):
                print("Getting image from memory cache...")
                let updatedMedia = Media(
                    id: media.id,
                    url: media.url,
                    data: cachedMedia.data,
                    type: media.type,
                    accessibilityLabel: media.accessibilityLabel
                )
                return .success(updatedMedia)
            case .inProgress(let task):
                print("Image download already in-progress...")
                do {
                    let result = try await task.value
                    await localDataSource.setCachedMedia(.ready(result), for: media.url)
                    return .success(result)
                } catch {
                    return .failure(.networkError(error))
                }
            }
        }
        
        // Check disk cache asynchronously (to avoid blocking main thread)
        if let cached = await localDataSource.getCachedMediaFromDisk(for: media.url) {
            switch cached {
            case .ready(let cachedMedia):
                print("Getting image from disk cache...")
                let updatedMedia = Media(
                    id: media.id,
                    url: media.url,
                    data: cachedMedia.data,
                    type: media.type,
                    accessibilityLabel: media.accessibilityLabel
                )
                return .success(updatedMedia)
            case .inProgress(let task):
                print("Image download already in-progress...")
                do {
                    let result = try await task.value
                    await localDataSource.setCachedMedia(.ready(result), for: media.url)
                    return .success(result)
                } catch {
                    return .failure(.networkError(error))
                }
            }
        }
        
        let task = Task<Media, Error> {
            do {
                print("Starting image download...")
                let data = try await remoteDataSource.downloadImage(from: media.url)
                
                let updatedMedia = Media(
                    id: media.id,
                    url: media.url,
                    data: data,
                    type: media.type,
                    accessibilityLabel: media.accessibilityLabel
                )
                
                return updatedMedia
            } catch {
                print("Failed to download image: \(error)")
                throw error
            }
        }
        
        await localDataSource.setCachedMedia(.inProgress(task), for: media.url)
        
        do {
            let result = try await task.value
            await localDataSource.setCachedMedia(.ready(result), for: media.url)
            return .success(result)
        } catch {
            return .failure(.networkError(error))
        }
    }
}

