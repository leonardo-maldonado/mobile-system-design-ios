import Foundation

struct RetryConfiguration {
    let maxAttempts: Int
    let baseDelay: TimeInterval
    
    init(maxAttempts: Int = 3, baseDelay: TimeInterval = 0.5) {
        self.maxAttempts = maxAttempts
        self.baseDelay = baseDelay
    }
}
