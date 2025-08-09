//
//  AsyncRetriable.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/9/25.
//
import Foundation

protocol AsyncRetryable {
    associatedtype Output
    func run() async throws -> Output
}

extension AsyncRetryable {
    func retry(
        maxAttempts: Int = 3,
        baseDelay: TimeInterval = 0.5,
        maxDelay: TimeInterval = 5.0,
        jitter: ClosedRange<Double> = 0.0...0.3,
        shouldRetry: @escaping (Error, Int) -> Bool = { _, _ in true },
        onBeforeRetry: ((Error, Int, TimeInterval) -> Void)? = nil
    ) async throws -> Output {
        try await Retrier.run(
            maxAttempts: maxAttempts,
            baseDelay: baseDelay,
            maxDelay: maxDelay,
            jitter: jitter,
            shouldRetry: shouldRetry,
            onBeforeRetry: onBeforeRetry,
            operation: { try await run() }
        )
    }
}
