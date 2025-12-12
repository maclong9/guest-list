import Fluent
import Foundation
import GuestListShared
import Hummingbird
import HummingbirdFluent
import Logging

/// Controller for guest management endpoints
struct GuestController: Sendable {
    let fluent: Fluent
    let validationService: ValidationService
    let logger: Logger

    init(fluent: Fluent, validationService: ValidationService, logger: Logger) {
        self.fluent = fluent
        self.validationService = validationService
        self.logger = logger
    }

    // MARK: - Routes

    func addRoutes(to group: RouterGroup<AppRequestContext>) {
        group.post(use: createGuest)
        group.get(":id", use: getGuest)
        group.put(":id/check-in", use: checkInGuest)
    }

    // MARK: - Handlers

    /// POST /api/v1/guests
    /// Add a guest to an event (owner/admin/staff)
    @Sendable
    private func createGuest(_ request: Request, context: AppRequestContext) async throws -> Response {
        // Only owner/admin/staff can add guests
        let payload = try context.requireRole(oneOf: [.owner, .admin, .staff])

        // Decode request
        let createRequest = try await request.decode(as: CreateGuestRequest.self, context: context)

        // Verify event exists and belongs to user's venue
        guard let eventModel = try await EventModel.query(on: fluent.db())
            .filter(\.$id == createRequest.eventID)
            .filter(\.$venue.$id == payload.venueID)
            .first()
        else {
            throw HTTPError(.notFound, message: "Event not found")
        }

        let event = eventModel.toDTO()

        // Check capacity if event has a limit
        if event.capacity != nil {
            let currentGuestCount = try await GuestModel.query(on: fluent.db())
                .filter(\.$event.$id == event.id)
                .count()
            try validationService.validateCapacity(event: event, currentGuestCount: currentGuestCount)
        }

        // Create guest DTO
        let guestDTO = Guest(
            id: UUID(),
            eventID: createRequest.eventID,
            firstName: createRequest.firstName,
            lastName: createRequest.lastName,
            email: createRequest.email,
            phoneNumber: createRequest.phoneNumber,
            ticketType: createRequest.ticketType ?? .general,
            isCheckedIn: false,
            checkedInAt: nil,
            notes: createRequest.notes,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Save to database
        let guestModel = GuestModel(from: guestDTO)
        try await guestModel.save(on: fluent.db())

        logger.info("Created guest", metadata: [
            "guest_id": "\(guestDTO.id)",
            "event_id": "\(event.id)",
            "venue_id": "\(payload.venueID)",
            "user_id": "\(payload.sub)",
            "name": "\(guestDTO.fullName)",
        ])

        return try encodeJSONResponse(guestDTO, status: .created)
    }

    /// GET /api/v1/guests/:id
    /// Get guest details
    @Sendable
    private func getGuest(_ request: Request, context: AppRequestContext) async throws -> Response {
        // Get authenticated user
        let payload = try context.requireIdentity()

        // Extract guest ID from path
        guard let guestIDString = context.parameters.get("id", as: String.self),
            let guestID = UUID(uuidString: guestIDString)
        else {
            throw HTTPError(.badRequest, message: "Invalid guest ID")
        }

        // Fetch guest
        guard let guestModel = try await GuestModel.find(guestID, on: fluent.db()) else {
            throw HTTPError(.notFound, message: "Guest not found")
        }

        let guest = guestModel.toDTO()

        // Verify the guest's event belongs to user's venue
        guard let eventModel = try await EventModel.find(guest.eventID, on: fluent.db()),
            eventModel.$venue.id == payload.venueID
        else {
            throw HTTPError(.forbidden, message: "Access denied to this guest's event")
        }

        return try encodeJSONResponse(guest)
    }

    /// PUT /api/v1/guests/:id/check-in
    /// Check in a guest (owner/admin/staff)
    @Sendable
    private func checkInGuest(_ request: Request, context: AppRequestContext) async throws -> Response {
        // Only owner/admin/staff can check in guests
        let payload = try context.requireRole(oneOf: [.owner, .admin, .staff])

        // Extract guest ID from path
        guard let guestIDString = context.parameters.get("id", as: String.self),
            let guestID = UUID(uuidString: guestIDString)
        else {
            throw HTTPError(.badRequest, message: "Invalid guest ID")
        }

        // Fetch guest
        guard let guestModel = try await GuestModel.find(guestID, on: fluent.db()) else {
            throw HTTPError(.notFound, message: "Guest not found")
        }

        let guest = guestModel.toDTO()

        // Verify the guest's event belongs to user's venue
        guard let eventModel = try await EventModel.find(guest.eventID, on: fluent.db()),
            eventModel.$venue.id == payload.venueID
        else {
            throw HTTPError(.forbidden, message: "Access denied to this guest's event")
        }

        let event = eventModel.toDTO()

        // Validate that check-in is allowed for this event
        try validationService.canCheckInGuest(event: event)

        // Check if already checked in (idempotent operation)
        let alreadyCheckedIn = guest.isCheckedIn

        // Perform check-in if not already checked in
        if !alreadyCheckedIn {
            guestModel.isCheckedIn = true
            guestModel.checkedInAt = Date()
            guestModel.updatedAt = Date()
            try await guestModel.save(on: fluent.db())

            logger.info("Checked in guest", metadata: [
                "guest_id": "\(guestID)",
                "event_id": "\(event.id)",
                "venue_id": "\(payload.venueID)",
                "user_id": "\(payload.sub)",
                "name": "\(guest.fullName)",
            ])
        } else {
            logger.info("Guest already checked in", metadata: [
                "guest_id": "\(guestID)",
                "checked_in_at": "\(guest.checkedInAt?.ISO8601Format() ?? "unknown")",
            ])
        }

        let updatedGuest = guestModel.toDTO()
        let response = CheckInResponse(
            guest: updatedGuest,
            alreadyCheckedIn: alreadyCheckedIn
        )

        return try encodeJSONResponse(response)
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

/// Request body for creating a guest
struct CreateGuestRequest: Codable, Sendable {
    let eventID: UUID
    let firstName: String
    let lastName: String
    let email: String?
    let phoneNumber: String?
    let ticketType: TicketType?
    let notes: String?
}

// MARK: - Response DTOs

/// Response for guest check-in operation
struct CheckInResponse: Codable, Sendable {
    let guest: Guest
    let alreadyCheckedIn: Bool
}
