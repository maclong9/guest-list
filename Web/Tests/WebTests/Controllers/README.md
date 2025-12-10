# Controller Tests

Test API endpoint handlers:
- Request validation
- Response formatting
- Status codes
- Authentication/authorization
- Error responses

Example:
```swift
import Testing
import Hummingbird
import HummingbirdTesting
@testable import Web

@Suite("Event Controller Tests")
struct EventControllerTests {
    @Test("GET /api/v1/events returns events list")
    func testListEvents() async throws {
        let app = buildApplication()

        try await app.test(.router) { client in
            try await client.execute(uri: "/api/v1/events", method: .get) { response in
                #expect(response.status == .ok)
                #expect(response.headers[.contentType] == "application/json")
            }
        }
    }

    @Test("POST /api/v1/events creates event")
    func testCreateEvent() async throws {
        // Test event creation
    }
}
```
