import Testing

@testable import GuestListShared

@Suite("GuestListShared Tests")
struct GuestListSharedTests {
    @Test("Library version is correct")
    func testVersion() {
        #expect(version == "1.0.0")
    }

    @Test("Shared module initializes")
    func testInitialization() {
        let shared = GuestListShared()
        // Just verify it creates an instance
        #expect(type(of: shared) == GuestListShared.self)
    }
}
