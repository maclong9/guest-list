import Foundation
import FluentGen

/// Represents a user who can access the system
@FluentModel
public struct User: Codable, Identifiable, Sendable, Hashable {
    public let id: UUID

    public var venueID: UUID

    public var email: String

    public var firstName: String

    public var lastName: String

    public var role: UserRole

    public var isActive: Bool

    public var createdAt: Date

    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        venueID: UUID,
        email: String,
        firstName: String,
        lastName: String,
        role: UserRole = .staff,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.venueID = venueID
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.role = role
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var fullName: String {
        "\(firstName) \(lastName)"
    }
}

/// User roles with hierarchical permissions
public enum UserRole: String, Codable, Sendable {
    case owner      // Full access, billing
    case admin      // Full access, no billing
    case staff      // Event management, check-ins
    case performer  // View own events, guest list
    case guest      // View tickets, chat
}
