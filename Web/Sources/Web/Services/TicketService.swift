import Crypto
import Foundation
import Hummingbird

/// Service for QR code generation and validation
/// Provides HMAC-SHA256 signed QR codes for offline ticket validation
actor TicketService: Sendable {
    private let hmacSecret: String

    init(hmacSecret: String) {
        self.hmacSecret = hmacSecret
    }

    // MARK: - QR Code Generation

    /// Generate QR code data and HMAC signature for a ticket
    /// - Parameters:
    ///   - ticketID: Unique ticket identifier
    ///   - eventID: Event the ticket is for
    ///   - guestID: Guest who owns the ticket
    /// - Returns: Tuple of (qrCode, hmacSignature)
    ///
    /// QR format: `ticket:{ticketID}:{eventID}:{guestID}`
    /// Signature allows offline validation without database access
    func generateTicketData(ticketID: UUID, eventID: UUID, guestID: UUID) throws -> (qrCode: String, hmacSignature: String) {
        let qrCode = "ticket:\(ticketID):\(eventID):\(guestID)"
        let signature = try generateSignature(for: qrCode)
        return (qrCode, signature)
    }

    // MARK: - Validation

    /// Validate HMAC signature for a QR code
    /// - Parameters:
    ///   - qrCode: QR code string to validate
    ///   - signature: HMAC signature to verify
    /// - Returns: True if signature is valid, false otherwise
    ///
    /// This method is offline-capable - it only validates the signature,
    /// not the current state of the ticket in the database
    func validateSignature(qrCode: String, signature: String) -> Bool {
        do {
            let expectedSignature = try generateSignature(for: qrCode)
            return expectedSignature == signature
        } catch {
            return false
        }
    }

    /// Parse QR code string to extract ticket, event, and guest IDs
    /// - Parameter qrCode: QR code string in format `ticket:{ticketID}:{eventID}:{guestID}`
    /// - Returns: Tuple of (ticketID, eventID, guestID)
    /// - Throws: TicketError if QR code format is invalid
    func parseQRCode(_ qrCode: String) throws -> (ticketID: UUID, eventID: UUID, guestID: UUID) {
        let components = qrCode.split(separator: ":")
        guard components.count == 4,
            components[0] == "ticket",
            let ticketID = UUID(uuidString: String(components[1])),
            let eventID = UUID(uuidString: String(components[2])),
            let guestID = UUID(uuidString: String(components[3]))
        else {
            throw TicketError.invalidQRCodeFormat
        }

        return (ticketID, eventID, guestID)
    }

    // MARK: - Private Helpers

    /// Generate HMAC-SHA256 signature for QR code data
    private func generateSignature(for qrCode: String) throws -> String {
        guard let qrData = qrCode.data(using: .utf8),
            let secretData = hmacSecret.data(using: .utf8)
        else {
            throw TicketError.signatureGenerationFailed
        }

        let signature = HMAC<SHA256>.authenticationCode(for: qrData, using: SymmetricKey(data: secretData))
        return Data(signature).base64EncodedString()
    }
}

// MARK: - Ticket Errors

enum TicketError: Error, Sendable {
    case invalidQRCodeFormat
    case signatureGenerationFailed
    case invalidSignature
}
