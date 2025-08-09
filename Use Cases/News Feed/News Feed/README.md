## Networking

- `HTTPClient` abstracts network calls with async/await. `URLSessionHTTPClient` is the default implementation.
- Supports JSON encoding/decoding, interceptors, and retry via `RetryPolicy`.

### Usage

```swift
let client = URLSessionHTTPClient(
    config: HTTPClientConfig(baseURL: URL(string: "https://api.yourservice.com")!)
)

let feedEndpoint = Endpoint(path: "/feed", method: .get)
let feed: FeedResponseDTO = try await client.send(feedEndpoint)

let likeEndpoint = Endpoint(path: "/posts/123/like", method: .post)
try await client.send(likeEndpoint, body: PostInteractionRequestDTO(id: "123", type: "like"))
```

## Retry Utilities

- Prefer `RetryPolicy` inside `URLSessionHTTPClient` for HTTP retries.
- Use `Retrier.run` for non-HTTP async operations with backoff and jitter.

```swift
let result: T = try await Retrier.run(
    maxAttempts: 3,
    baseDelay: 0.5,
    maxDelay: 5.0,
    jitter: 0.0...0.3,
    shouldRetry: { error, _ in (error as? URLError) != nil },
    operation: {
        try await doSomethingAsync()
    }
)
```


