import Fluent
import Foundation
import GuestListShared
import Hummingbird
import HummingbirdFluent
import Logging

/// Controller for ticket management and QR validation endpoints
struct TicketController: Sendable {
    let fluent: Fluent
    let ticketService: TicketService
    let logger: Logger

    init(fluent: Fluent, ticketService: TicketService, logger: Logger) {
        self.fluent = fluent
        self.ticketService = ticketService
        self.logger = logger
    }

    // MARK: - Routes

    func addRoutes(to group: RouterGroup<AppRequestContext>) {
        group.get(":id", use: getTicket)
        group.post("validate", use: validateTicket)
        group.post("generate", use: generateTicket)
    }

    // MARK: - Handlers

    /// GET /api/v1/tickets/:id
    /// Get ticket details with guest and event information
    @Sendable
    private func getTicket(_ request: Request, context: AppRequestContext) async throws -> Response {
        // Get authenticated user
        let payload = try context.requireIdentity()

        // Extract ticket ID from path
        guard let ticketIDString = context.parameters.get("id", as: String.self),
            let ticketID = UUID(uuidString: ticketIDString)
        else {
            throw HTTPError(.badRequest, message: "Invalid ticket ID")
        }

        // Fetch ticket
        guard let ticketModel = try await TicketModel.find(ticketID, on: fluent.db()) else {
            throw HTTPError(.notFound, message: "Ticket not found")
        }

        let ticket = ticketModel.toDTO()

        // Fetch associated guest
        guard let guestModel = try await GuestModel.find(ticket.guestID, on: fluent.db()) else {
            throw HTTPError(.notFound, message: "Guest not found for ticket")
        }

        let guest = guestModel.toDTO()

        // Fetch associated event and verify it belongs to user's venue
        guard let eventModel = try await EventModel.find(ticket.eventID, on: fluent.db()),
            eventModel.$venue.id == payload.venueID
        else {
            throw HTTPError(.forbidden, message: "Access denied to this ticket's event")
        }

        let event = eventModel.toDTO()

        let response = TicketDetailsResponse(
            ticket: ticket,
            guest: guest,
            event: event
        )

        return try encodeJSONResponse(response)
    }

    /// POST /api/v1/tickets/validate
    /// Validate a ticket QR code with HMAC signature
    @Sendable
    private func validateTicket(_ request: Request, context: AppRequestContext) async throws -> Response {
        // Only owner/admin/staff can validate tickets
        let payload = try context.requireRole(oneOf: [.owner, .admin, .staff])

        // Decode validation request
        let validationRequest = try await request.decode(as: TicketValidationRequest.self, context: context)

        // Step 1: Verify HMAC signature (offline-capable)
        let isSignatureValid = await ticketService.validateSignature(
            qrCode: validationRequest.qrCode,
            signature: validationRequest.hmacSignature
        )

        guard isSignatureValid else {
            logger.warning("Invalid ticket signature", metadata: [
                "venue_id": "\(payload.venueID)",
                "user_id": "\(payload.sub)",
            ])

            let response = TicketValidationResponse(
                isValid: false,
                message: "Invalid ticket signature - ticket may be forged"
            )
            return try encodeJSONResponse(response)
        }

        // Step 2: Parse QR code to extract IDs
        let (ticketID, eventID, guestID) = try await ticketService.parseQRCode(validationRequest.qrCode)

        // Step 3: Check ticket exists in database
        guard let ticketModel = try await TicketModel.find(ticketID, on: fluent.db()) else {
            logger.warning("Ticket not found in database", metadata: [
                "ticket_id": "\(ticketID)",
                "venue_id": "\(payload.venueID)",
            ])

            let response = TicketValidationResponse(
                isValid: false,
                message: "Ticket not found in system"
            )
            return try encodeJSONResponse(response)
        }

        let ticket = ticketModel.toDTO()

        // Step 4: Check isValid flag
        guard ticket.isValid else {
            logger.warning("Ticket marked as invalid", metadata: [
                "ticket_id": "\(ticketID)",
                "venue_id": "\(payload.venueID)",
            ])

            let response = TicketValidationResponse(
                isValid: false,
                ticket: ticket,
                message: "Ticket has been revoked"
            )
            return try encodeJSONResponse(response)
        }

        // Step 5: Verify event belongs to user's venue
        guard let eventModel = try await EventModel.find(eventID, on: fluent.db()),
            eventModel.$venue.id == payload.venueID
        else {
            logger.warning("Ticket event does not belong to venue", metadata: [
                "ticket_id": "\(ticketID)",
                "event_id": "\(eventID)",
                "venue_id": "\(payload.venueID)",
            ])

            let response = TicketValidationResponse(
                isValid: false,
                message: "Ticket is not valid for this venue"
            )
            return try encodeJSONResponse(response)
        }

        let event = eventModel.toDTO()

        // Fetch guest information
        guard let guestModel = try await GuestModel.find(guestID, on: fluent.db()) else {
            logger.warning("Guest not found for ticket", metadata: [
                "ticket_id": "\(ticketID)",
                "guest_id": "\(guestID)",
            ])

            let response = TicketValidationResponse(
                isValid: false,
                ticket: ticket,
                event: event,
                message: "Guest not found"
            )
            return try encodeJSONResponse(response)
        }

        let guest = guestModel.toDTO()

        // Step 6: Mark as validated
        if ticketModel.validatedAt == nil {
            ticketModel.validatedAt = Date()
            ticketModel.updatedAt = Date()
            try await ticketModel.save(on: fluent.db())

            logger.info("Validated ticket", metadata: [
                "ticket_id": "\(ticketID)",
                "event_id": "\(eventID)",
                "guest_id": "\(guestID)",
                "venue_id": "\(payload.venueID)",
                "user_id": "\(payload.sub)",
                "guest_name": "\(guest.fullName)",
            ])
        } else {
            logger.info("Ticket already validated", metadata: [
                "ticket_id": "\(ticketID)",
                "validated_at": "\(ticket.validatedAt?.ISO8601Format() ?? "unknown")",
            ])
        }

        let updatedTicket = ticketModel.toDTO()
        let response = TicketValidationResponse(
            isValid: true,
            ticket: updatedTicket,
            guest: guest,
            event: event,
            message: "Ticket is valid"
        )

        return try encodeJSONResponse(response)
    }

    /// POST /api/v1/tickets/generate
    /// Generate a ticket with QR code for a guest
    @Sendable
    private func generateTicket(_ request: Request, context: AppRequestContext) async throws -> Response {
        // Only owner/admin/staff can generate tickets
        let payload = try context.requireRole(oneOf: [.owner, .admin, .staff])

        // Decode request
        let generateRequest = try await request.decode(as: GenerateTicketRequest.self, context: context)

        // Fetch guest
        guard let guestModel = try await GuestModel.find(generateRequest.guestID, on: fluent.db()) else {
            throw HTTPError(.notFound, message: "Guest not found")
        }

        let guest = guestModel.toDTO()

        // Verify event belongs to user's venue
        guard let eventModel = try await EventModel.find(guest.eventID, on: fluent.db()),
            eventModel.$venue.id == payload.venueID
        else {
            throw HTTPError(.forbidden, message: "Access denied to this guest's event")
        }

        let event = eventModel.toDTO()

        // Check if ticket already exists for this guest
        let existingTicket = try await TicketModel.query(on: fluent.db())
            .filter(\.$guest.$id == guest.id)
            .first()

        if let existing = existingTicket {
            logger.info("Ticket already exists for guest", metadata: [
                "ticket_id": "\(existing.id)",
                "guest_id": "\(guest.id)",
            ])

            let ticket = existing.toDTO()
            return try encodeJSONResponse(ticket)
        }

        // Generate new ticket
        let ticketID = UUID()
        let (qrCode, hmacSignature) = try await ticketService.generateTicketData(
            ticketID: ticketID,
            eventID: event.id,
            guestID: guest.id
        )

        let ticketDTO = Ticket(
            id: ticketID,
            eventID: event.id,
            guestID: guest.id,
            qrCode: qrCode,
            hmacSignature: hmacSignature,
            isValid: true,
            validatedAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Save to database
        let ticketModel = TicketModel(from: ticketDTO)
        try await ticketModel.save(on: fluent.db())

        logger.info("Generated ticket", metadata: [
            "ticket_id": "\(ticketID)",
            "event_id": "\(event.id)",
            "guest_id": "\(guest.id)",
            "venue_id": "\(payload.venueID)",
            "user_id": "\(payload.sub)",
            "guest_name": "\(guest.fullName)",
        ])

        return try encodeJSONResponse(ticketDTO, status: .created)
    }

    // MARK: - Helper Methods

    private func encodeJSONResponse<T: Encodable>(_ value: T, status: HTTPResponse.Status = .ok) throws -> Response {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(value)
        return Response(
            status: status,
            headers: [.contentType: "application/json"],
            body: .init(byteBuffer: .init(data: data))
        )
    }
}

// MARK: - Request DTOs

/// Request body for generating a ticket
struct GenerateTicketRequest: Codable, Sendable {
    let guestID: UUID
}

// MARK: - Response DTOs

/// Response for ticket details with full context
struct TicketDetailsResponse: Codable, Sendable {
    let ticket: Ticket
    let guest: Guest
    let event: Event
}
