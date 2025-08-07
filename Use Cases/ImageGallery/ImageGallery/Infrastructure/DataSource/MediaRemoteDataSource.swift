//
//  MediaRemoteDataSource.swift
//  ImageGallery
//
//  Created by Leonardo Maldonado on 7/20/25.
//

import Foundation

protocol AsyncRetryable {
    associatedtype Output
    func run() async throws -> Output
}

extension AsyncRetryable {
    func retry(maxAttempts: Int, baseDelay: TimeInterval) async throws -> Output {
        var attempt = 0
        var currentDelay = baseDelay
        
        while true {
            do {
                return try await run()
            } catch {
                print("Retrying... attempt: \(attempt), error: \(error)")
                attempt += 1
                if attempt >= maxAttempts {
                    throw error
                }
                try await Task.sleep(nanoseconds: UInt64(currentDelay * 1_000_000_000))
                currentDelay *= 2
            }
        }
    }
}

protocol MediaRemoteDataSourceProtocol: Sendable {
    func downloadImage(from url: URL) async throws -> Data
}

final class MediaRemoteDataSource: MediaRemoteDataSourceProtocol {
    
    enum NetworkError: Error {
        case invalidResponse
        case noData
    }
    
    private let urlSession: URLSession
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    private struct ImageDownloadTask: AsyncRetryable {
        typealias Output = Data
        
        let url: URL
        let urlSession: URLSession
        
        func run() async throws -> Data {
            let (data, response) = try await urlSession.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  200...299 ~= httpResponse.statusCode else {
                throw MediaRemoteDataSource.NetworkError.invalidResponse
            }
            
            guard !data.isEmpty else {
                throw MediaRemoteDataSource.NetworkError.noData
            }
            
            return data
        }
    }
    
    func downloadImage(from url: URL) async throws -> Data {
        let task = ImageDownloadTask(url: url, urlSession: urlSession)
        return try await task.retry(maxAttempts: 3, baseDelay: 0.5)
    }
}

