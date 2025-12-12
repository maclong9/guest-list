import Foundation
import FluentGen

/// Represents an event hosted by a venue
@FluentModel
public struct Event: Codable, Identifiable, Sendable, Hashable {
    public let id: UUID
    public var venueID: UUID
    public var name: String
    public var description: String?
    public var startTime: Date
    public var endTime: Date
    public var location: String?
    public var capacity: Int?
    public var status: EventStatus
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        venueID: UUID,
        name: String,
        description: String? = nil,
        startTime: Date,
        endTime: Date,
        location: String? = nil,
        capacity: Int? = nil,
        status: EventStatus = .upcoming,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.venueID = venueID
        self.name = name
        self.description = description
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.capacity = capacity
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Event lifecycle status
public enum EventStatus: String, Codable, Sendable {
    case upcoming   // Not yet started
    case live       // Currently happening
    case ended      // Completed
    case cancelled  // Cancelled
}
