import Foundation
import FluentGen

/// Represents a digital ticket with QR code
@FluentModel
public struct Ticket: Codable, Identifiable, Sendable, Hashable {
    public let id: UUID
    public var eventID: UUID
    public var guestID: UUID
    public var qrCode: String
    public var hmacSignature: String
    public var isValid: Bool
    public var validatedAt: Date?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        eventID: UUID,
        guestID: UUID,
        qrCode: String,
        hmacSignature: String,
        isValid: Bool = true,
        validatedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.eventID = eventID
        self.guestID = guestID
        self.qrCode = qrCode
        self.hmacSignature = hmacSignature
        self.isValid = isValid
        self.validatedAt = validatedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Request to validate a ticket
public struct TicketValidationRequest: Codable, Sendable {
    public let qrCode: String
    public let hmacSignature: String

    public init(qrCode: String, hmacSignature: String) {
        self.qrCode = qrCode
        self.hmacSignature = hmacSignature
    }
}

/// Response from ticket validation
public struct TicketValidationResponse: Codable, Sendable {
    public let isValid: Bool
    public let ticket: Ticket?
    public let guest: Guest?
    public let event: Event?
    public let message: String?

    public init(
        isValid: Bool,
        ticket: Ticket? = nil,
        guest: Guest? = nil,
        event: Event? = nil,
        message: String? = nil
    ) {
        self.isValid = isValid
        self.ticket = ticket
        self.guest = guest
        self.event = event
        self.message = message
    }
}
