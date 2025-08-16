//
//  RetryableMacro.swift
//  RetryableMacro
//
//  Created by Leonardo Maldonado on 8/9/25.
//

import Foundation

/// A macro that adds retry functionality to async functions.
///
/// ## Usage
/// ```swift
/// @Retryable(maxAttempts: 3, baseDelay: 1.0, maxDelay: 5.0)
/// func fetchData() async throws -> Data {
///     // Your async operation here
/// }
/// ```
///
/// The macro will automatically generate a retryable version of your function
/// with exponential backoff and jitter.
@attached(peer)
public macro Retryable(
    maxAttempts: Int = 3,
    baseDelay: TimeInterval = 0.5,
    maxDelay: TimeInterval = 5.0,
    jitter: ClosedRange<Double> = 0.0...0.3
) = #externalMacro(
    module: "RetryableMacroMacros",
    type: "RetryableMacro"
)

/// A macro that adds retry functionality with custom retry logic.
///
/// ## Usage
/// ```swift
/// @RetryableWithCondition(maxAttempts: 3, shouldRetry: { error, attempt in
///     return error is NetworkError && attempt < 3
/// })
/// func fetchData() async throws -> Data {
///     // Your async operation here
/// }
/// ```
///
/// The macro will automatically generate a retryable version of your function
/// with custom retry logic.
@attached(peer)
public macro RetryableWithCondition(
    maxAttempts: Int = 3,
    baseDelay: TimeInterval = 0.5,
    maxDelay: TimeInterval = 5.0,
    jitter: ClosedRange<Double> = 0.0...0.3,
    shouldRetry: @escaping (Error, Int) -> Bool
) = #externalMacro(
    module: "RetryableMacroMacros",
    type: "RetryableWithConditionMacro"
)