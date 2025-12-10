import Foundation
import FluentGen

/// Represents a guest on an event's guest list
@FluentModel
public struct Guest: Codable, Identifiable, Sendable, Hashable {
    public let id: UUID

    public var eventID: UUID

    public var firstName: String

    public var lastName: String

    public var email: String?

    public var phoneNumber: String?

    public var ticketType: TicketType

    public var isCheckedIn: Bool

    public var checkedInAt: Date?

    public var notes: String?

    public var createdAt: Date

    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        eventID: UUID,
        firstName: String,
        lastName: String,
        email: String? = nil,
        phoneNumber: String? = nil,
        ticketType: TicketType = .general,
        isCheckedIn: Bool = false,
        checkedInAt: Date? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.eventID = eventID
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phoneNumber = phoneNumber
        self.ticketType = ticketType
        self.isCheckedIn = isCheckedIn
        self.checkedInAt = checkedInAt
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var fullName: String {
        "\(firstName) \(lastName)"
    }
}

/// Type of ticket/entry
public enum TicketType: String, Codable, Sendable {
    case general    // General admission
    case vip        // VIP access
    case backstage  // Backstage pass
    case press      // Press/media
    case comp       // Complimentary
    case guestList  // On the list
}
