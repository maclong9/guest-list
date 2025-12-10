# Integration Tests

End-to-end tests with real containers:
- Database operations (PostgreSQL)
- Cache operations (Redis)
- WebSocket connections
- Full request/response cycle

These tests require containers to be running:
```sh
make containers-up
swift test --filter Integration
```

Example:
```swift
import Testing
@testable import Web

@Suite("Database Integration Tests")
struct DatabaseIntegrationTests {
    @Test("Can connect to PostgreSQL")
    func testDatabaseConnection() async throws {
        // Test actual database connection
        // let db = try await connectToDatabase()
        // #expect(db != nil)
    }

    @Test("Can store and retrieve events")
    func testEventPersistence() async throws {
        // Create event in database
        // Retrieve it
        // Verify data matches
    }
}
```

**Setup:**
1. Ensure `.env` is configured for testing
2. Run `make containers-up` before tests
3. Tests should clean up after themselves
4. Use separate test database (guestlist_test)
