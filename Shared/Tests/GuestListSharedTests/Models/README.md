# Model Tests

Test domain models for:
- Codable conformance (encoding/decoding)
- Sendable conformance
- Validation logic
- Business rules
- Edge cases

Example:
```swift
import Testing
@testable import GuestListShared

@Suite("Event Model Tests")
struct EventTests {
    @Test("Event encodes and decodes correctly")
    func testCodable() throws {
        let event = Event(
            id: UUID(),
            venueID: UUID(),
            name: "Test Event",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600),
            status: .upcoming
        )

        let encoded = try JSONEncoder().encode(event)
        let decoded = try JSONDecoder().decode(Event.self, from: encoded)

        #expect(decoded.id == event.id)
        #expect(decoded.name == event.name)
    }
}
```
