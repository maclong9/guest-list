# Service Tests

Test services with mocked dependencies:
- APIClient (with mocked URLSession)
- WebSocketService (with mocked connections)
- Network error handling
- Retry logic
- Timeout behavior

Example:
```swift
import Testing
@testable import GuestListShared

@Suite("APIClient Tests")
struct APIClientTests {
    @Test("Fetches events successfully")
    func testFetchEvents() async throws {
        // Use URLProtocol mocking or dependency injection
        let client = APIClient(baseURL: URL(string: "https://test.example.com")!)

        // Mock successful response
        // let events = try await client.fetchEvents()
        // #expect(events.count > 0)
    }

    @Test("Handles network errors gracefully")
    func testNetworkError() async {
        // Test error handling
    }
}
```
