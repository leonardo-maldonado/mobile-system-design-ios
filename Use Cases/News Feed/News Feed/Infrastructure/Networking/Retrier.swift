import Foundation

struct Retrier {
    static func run<T>(
        maxAttempts: Int = 3,
        baseDelay: TimeInterval = 0.5,
        maxDelay: TimeInterval = 5.0,
        jitter: ClosedRange<Double> = 0.0...0.3,
        shouldRetry: @escaping (Error, Int) -> Bool,
        onBeforeRetry: ((Error, Int, TimeInterval) -> Void)? = nil,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var attempt = 1
        var delay = baseDelay

        while true {
            try Task.checkCancellation()
            do {
                return try await operation()
            } catch {
                guard attempt < maxAttempts, shouldRetry(error, attempt) else { throw error }
                let jitterFactor = 1 + Double.random(in: jitter)
                let wait = min(maxDelay, delay) * jitterFactor
                onBeforeRetry?(error, attempt, wait)
                try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
                delay *= 2
                attempt += 1
            }
        }
    }
}


