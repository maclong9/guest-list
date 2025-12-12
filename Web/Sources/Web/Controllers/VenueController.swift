import Fluent
import Foundation
import GuestListShared
import Hummingbird
import HummingbirdFluent
import Logging

/// Controller for venue management endpoints
struct VenueController: Sendable {
    let fluent: Fluent
    let logger: Logger

    init(fluent: Fluent, logger: Logger) {
        self.fluent = fluent
        self.logger = logger
    }

    // MARK: - Routes

    func addRoutes(to group: RouterGroup<AppRequestContext>) {
        group.get(":id", use: getVenue)
        group.put(":id", use: updateVenue)
        group.get(":id/events", use: getVenueEvents)
    }

    // MARK: - Handlers

    /// GET /api/v1/venues/:id
    /// Get venue details
    @Sendable
    private func getVenue(_ request: Request, context: AppRequestContext) async throws -> Response {
        // Extract venue ID from path
        guard let venueIDString = context.parameters.get("id", as: String.self),
            let venueID = UUID(uuidString: venueIDString)
        else {
            throw HTTPError(.badRequest, message: "Invalid venue ID")
        }

        // Verify user can access this venue
        let payload = try context.requireVenueAccess(venueID)

        // Fetch venue
        guard let venueModel = try await VenueModel.find(venueID, on: fluent.db()) else {
            throw HTTPError(.notFound, message: "Venue not found")
        }

        let venue = venueModel.toDTO()
        return try encodeJSONResponse(venue)
    }

    /// PUT /api/v1/venues/:id
    /// Update venue details (owner/admin only)
    @Sendable
    private func updateVenue(_ request: Request, context: AppRequestContext) async throws -> Response {
        // Only owner/admin can update venue
        let payload = try context.requireRole(oneOf: [.owner, .admin])

        // Extract venue ID from path
        guard let venueIDString = context.parameters.get("id", as: String.self),
            let venueID = UUID(uuidString: venueIDString)
        else {
            throw HTTPError(.badRequest, message: "Invalid venue ID")
        }

        // Verify user can access this venue
        try context.requireVenueAccess(venueID)

        // Decode update request
        let updateRequest = try await request.decode(as: UpdateVenueRequest.self, context: context)

        // Fetch existing venue
        guard let venueModel = try await VenueModel.find(venueID, on: fluent.db()) else {
            throw HTTPError(.notFound, message: "Venue not found")
        }

        // Update fields if provided
        if let name = updateRequest.name {
            venueModel.name = name
        }
        if let email = updateRequest.email {
            // Validate email format
            guard email.contains("@") else {
                throw HTTPError(.badRequest, message: "Invalid email format")
            }
            venueModel.email = email
        }
        if let phoneNumber = updateRequest.phoneNumber {
            venueModel.phoneNumber = phoneNumber
        }
        if let address = updateRequest.address {
            venueModel.address = address
        }
        if let city = updateRequest.city {
            venueModel.city = city
        }
        if let state = updateRequest.state {
            venueModel.state = state
        }
        if let zipCode = updateRequest.zipCode {
            venueModel.zipCode = zipCode
        }
        if let country = updateRequest.country {
            venueModel.country = country
        }
        if let tier = updateRequest.tier {
            venueModel.tier = tier.rawValue
        }
        if let isActive = updateRequest.isActive {
            venueModel.isActive = isActive
        }

        // Update timestamp
        venueModel.updatedAt = Date()

        // Save changes
        try await venueModel.save(on: fluent.db())

        logger.info("Updated venue", metadata: ["venue_id": "\(venueID)", "user_id": "\(payload.sub)"])

        let updatedVenue = venueModel.toDTO()
        return try encodeJSONResponse(updatedVenue)
    }

    /// GET /api/v1/venues/:id/events
    /// Get all events for a venue
    @Sendable
    private func getVenueEvents(_ request: Request, context: AppRequestContext) async throws -> Response {
        // Extract venue ID from path
        guard let venueIDString = context.parameters.get("id", as: String.self),
            let venueID = UUID(uuidString: venueIDString)
        else {
            throw HTTPError(.badRequest, message: "Invalid venue ID")
        }

        // Verify user can access this venue
        let payload = try context.requireVenueAccess(venueID)

        // Fetch all events for this venue
        let eventModels = try await EventModel.query(on: fluent.db())
            .filter(\.$venue.$id == venueID)
            .sort(\.$startTime, .descending)
            .all()

        let events = eventModels.map { $0.toDTO() }

        logger.info("Retrieved venue events", metadata: [
            "venue_id": "\(venueID)",
            "event_count": "\(events.count)",
        ])

        return try encodeJSONResponse(events)
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

/// Request body for updating a venue
struct UpdateVenueRequest: Codable, Sendable {
    let name: String?
    let email: String?
    let phoneNumber: String?
    let address: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let country: String?
    let tier: VenueTier?
    let isActive: Bool?
}
