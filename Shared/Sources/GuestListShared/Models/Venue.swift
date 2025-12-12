import Foundation
import FluentGen

/// Represents a venue (customer) that hosts events
@FluentModel
public struct Venue: Codable, Identifiable, Sendable, Hashable {
    public let id: UUID
    public var name: String
    public var email: String
    public var phoneNumber: String?
    public var address: String?
    public var city: String?
    public var state: String?
    public var zipCode: String?
    public var country: String
    public var tier: VenueTier
    public var isActive: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        email: String,
        phoneNumber: String? = nil,
        address: String? = nil,
        city: String? = nil,
        state: String? = nil,
        zipCode: String? = nil,
        country: String = "US",
        tier: VenueTier = .free,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phoneNumber = phoneNumber
        self.address = address
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.country = country
        self.tier = tier
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Subscription tier for venues
public enum VenueTier: String, Codable, Sendable {
    case free
    case basic
    case premium
    case enterprise
}
