import Testing

@testable import Web

@Suite("Web Backend Tests")
struct BackendTests {
    @Test("Example test")
    func testExample() {
        // Basic test to ensure package compiles
        #expect(Bool(true))
    }
}
