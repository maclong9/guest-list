import Fluent
import Foundation
import GuestListShared
import Hummingbird
import HummingbirdFluent
import Logging

/// Controller for event management endpoints
struct EventController: Sendable {
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
        group.post(use: createEvent)
        group.get(use: listEvents)
        group.get(":id", use: getEvent)
        group.put(":id", use: updateEvent)
        group.delete(":id", use: deleteEvent)
        group.get(":id/guests", use: getEventGuests)
    }

    // MARK: - Handlers

    /// POST /api/v1/events
    /// Create a new event (owner/admin/staff)
    @Sendable
    private func createEvent(_ request: Request, context: AppRequestContext) async throws -> Response {
        // Only owner/admin/staff can create events
        let payload = try context.requireRole(oneOf: [.owner, .admin, .staff])

        // Decode request
        let createRequest = try await request.decode(as: CreateEventRequest.self, context: context)

        // Validate event dates
        try validationService.validateEventDates(startTime: createRequest.startTime, endTime: createRequest.endTime)

        // Create event DTO
        let eventDTO = Event(
            id: UUID(),
            venueID: payload.venueID,
            name: createRequest.name,
            description: createRequest.description,
            startTime: createRequest.startTime,
            endTime: createRequest.endTime,
            location: createRequest.location,
            capacity: createRequest.capacity,
            status: .upcoming,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Save to database
        let eventModel = EventModel(from: eventDTO)
        try await eventModel.save(on: fluent.db())

        logger.info("Created event", metadata: [
            "event_id": "\(eventDTO.id)",
            "venue_id": "\(payload.venueID)",
            "user_id": "\(payload.sub)",
            "name": "\(eventDTO.name)",
        ])

        return try encodeJSONResponse(eventDTO, status: .created)
    }

    /// GET /api/v1/events
    /// List events with pagination and optional status filter
    @Sendable
    private func listEvents(_ request: Request, context: AppRequestContext) async throws -> Response {
        // Get authenticated user
        let payload = try context.requireIdentity()

        // Parse pagination parameters
        let page = Int(request.uri.queryParameters.get("page") ?? "1") ?? 1
        let perPage = min(Int(request.uri.queryParameters.get("per_page") ?? "20") ?? 20, 100)
        let statusFilter = request.uri.queryParameters.get("status")

        // Build query scoped to user's venue
        var query = EventModel.query(on: fluent.db())
            .filter(\.$venue.$id == payload.venueID)

        // Apply status filter if provided
        if let statusString = statusFilter, let status = EventStatus(rawValue: statusString) {
            query = query.filter(\.$status == status.rawValue)
        }

        // Get total count for pagination metadata
        let totalCount = try await query.count()

        // Apply pagination and sorting
        let events = try await query
            .sort(\.$startTime, .descending)
            .range((page - 1) * perPage..<page * perPage)
            .all()
            .map { $0.toDTO() }

        let response = EventListResponse(
            events: events,
            page: page,
            perPage: perPage,
            total: totalCount
        )

        logger.info("Listed events", metadata: [
            "venue_id": "\(payload.venueID)",
            "page": "\(page)",
            "count": "\(events.count)",
            "total": "\(totalCount)",
        ])

        return try encodeJSONResponse(response)
    }

    /// GET /api/v1/events/:id
    /// Get event details
    @Sendable
    private func getEvent(_ request: Request, context: AppRequestContext) async throws -> Response {
        // Get authenticated user
        let payload = try context.requireIdentity()

        // Extract event ID from path
        guard let eventIDString = context.parameters.get("id", as: String.self),
            let eventID = UUID(uuidString: eventIDString)
        else {
            throw HTTPError(.badRequest, message: "Invalid event ID")
        }

        // Fetch event scoped to user's venue
        guard let eventModel = try await EventModel.query(on: fluent.db())
            .filter(\.$id == eventID)
            .filter(\.$venue.$id == payload.venueID)
            .first()
        else {
            throw HTTPError(.notFound, message: "Event not found")
        }

        let event = eventModel.toDTO()
        return try encodeJSONResponse(event)
    }

    /// PUT /api/v1/events/:id
    /// Update event details (owner/admin/staff, upcoming events only)
    @Sendable
    private func updateEvent(_ request: Request, context: AppRequestContext) async throws -> Response {
        // Only owner/admin/staff can update events
        let payload = try context.requireRole(oneOf: [.owner, .admin, .staff])

        // Extract event ID from path
        guard let eventIDString = context.parameters.get("id", as: String.self),
            let eventID = UUID(uuidString: eventIDString)
        else {
            throw HTTPError(.badRequest, message: "Invalid event ID")
        }

        // Fetch event scoped to user's venue
        guard let eventModel = try await EventModel.query(on: fluent.db())
            .filter(\.$id == eventID)
            .filter(\.$venue.$id == payload.venueID)
            .first()
        else {
            throw HTTPError(.notFound, message: "Event not found")
        }

        // Get current event DTO
        let currentEvent = eventModel.toDTO()

        // Decode update request
        let updateRequest = try await request.decode(as: UpdateEventRequest.self, context: context)

        // If updating name, description, location, or capacity - require event to be modifiable
        if updateRequest.name != nil || updateRequest.description != nil
            || updateRequest.location != nil || updateRequest.capacity != nil
        {
            try validationService.requireModifiableEvent(currentEvent)
        }

        // Update basic fields if provided
        if let name = updateRequest.name {
            eventModel.name = name
        }
        if let description = updateRequest.description {
            eventModel.description = description
        }
        if let location = updateRequest.location {
            eventModel.location = location
        }
        if let capacity = updateRequest.capacity {
            eventModel.capacity = capacity
        }

        // Handle date updates
        var newStartTime = currentEvent.startTime
        var newEndTime = currentEvent.endTime

        if let startTime = updateRequest.startTime {
            try validationService.requireModifiableEvent(currentEvent)
            newStartTime = startTime
        }
        if let endTime = updateRequest.endTime {
            try validationService.requireModifiableEvent(currentEvent)
            newEndTime = endTime
        }

        // If dates changed, validate them
        if newStartTime != currentEvent.startTime || newEndTime != currentEvent.endTime {
            try validationService.validateEventDates(startTime: newStartTime, endTime: newEndTime)
            eventModel.startTime = newStartTime
            eventModel.endTime = newEndTime
        }

        // Handle status updates
        if let newStatus = updateRequest.status {
            try validationService.validateStatusTransition(from: currentEvent.status, to: newStatus)
            eventModel.status = newStatus.rawValue
        }

        // Update timestamp
        eventModel.updatedAt = Date()

        // Save changes
        try await eventModel.save(on: fluent.db())

        logger.info("Updated event", metadata: [
            "event_id": "\(eventID)",
            "venue_id": "\(payload.venueID)",
            "user_id": "\(payload.sub)",
        ])

        let updatedEvent = eventModel.toDTO()
        return try encodeJSONResponse(updatedEvent)
    }

    /// DELETE /api/v1/events/:id
    /// Delete event (owner/admin only, upcoming events only)
    @Sendable
    private func deleteEvent(_ request: Request, context: AppRequestContext) async throws -> Response {
        // Only owner/admin can delete events
        let payload = try context.requireRole(oneOf: [.owner, .admin])

        // Extract event ID from path
        guard let eventIDString = context.parameters.get("id", as: String.self),
            let eventID = UUID(uuidString: eventIDString)
        else {
            throw HTTPError(.badRequest, message: "Invalid event ID")
        }

        // Fetch event scoped to user's venue
        guard let eventModel = try await EventModel.query(on: fluent.db())
            .filter(\.$id == eventID)
            .filter(\.$venue.$id == payload.venueID)
            .first()
        else {
            throw HTTPError(.notFound, message: "Event not found")
        }

        // Only upcoming events can be deleted
        let event = eventModel.toDTO()
        guard event.status == .upcoming else {
            throw HTTPError(.badRequest, message: "Only upcoming events can be deleted")
        }

        // Delete event (cascade will delete guests, tickets, messages)
        try await eventModel.delete(on: fluent.db())

        logger.info("Deleted event", metadata: [
            "event_id": "\(eventID)",
            "venue_id": "\(payload.venueID)",
            "user_id": "\(payload.sub)",
        ])

        // Return 204 No Content
        return Response(status: .noContent)
    }

    /// GET /api/v1/events/:id/guests
    /// Get guest list for an event
    @Sendable
    private func getEventGuests(_ request: Request, context: AppRequestContext) async throws -> Response {
        // Get authenticated user
        let payload = try context.requireIdentity()

        // Extract event ID from path
        guard let eventIDString = context.parameters.get("id", as: String.self),
            let eventID = UUID(uuidString: eventIDString)
        else {
            throw HTTPError(.badRequest, message: "Invalid event ID")
        }

        // Verify event exists and belongs to user's venue
        guard try await EventModel.query(on: fluent.db())
            .filter(\.$id == eventID)
            .filter(\.$venue.$id == payload.venueID)
            .first() != nil
        else {
            throw HTTPError(.notFound, message: "Event not found")
        }

        // Fetch all guests for this event
        let guestModels = try await GuestModel.query(on: fluent.db())
            .filter(\.$event.$id == eventID)
            .sort(\.$createdAt, .ascending)
            .all()

        let guests = guestModels.map { $0.toDTO() }
        let checkedInCount = guests.filter { $0.isCheckedIn }.count

        let response = GuestListResponse(
            eventID: eventID,
            guests: guests,
            totalCount: guests.count,
            checkedInCount: checkedInCount
        )

        logger.info("Retrieved guest list", metadata: [
            "event_id": "\(eventID)",
            "venue_id": "\(payload.venueID)",
            "total_guests": "\(guests.count)",
            "checked_in": "\(checkedInCount)",
        ])

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

/// Request body for creating an event
struct CreateEventRequest: Codable, Sendable {
    let name: String
    let description: String?
    let startTime: Date
    let endTime: Date
    let location: String?
    let capacity: Int?
}

/// Request body for updating an event
struct UpdateEventRequest: Codable, Sendable {
    let name: String?
    let description: String?
    let startTime: Date?
    let endTime: Date?
    let location: String?
    let capacity: Int?
    let status: EventStatus?
}

// MARK: - Response DTOs

/// Response for paginated event list
struct EventListResponse: Codable, Sendable {
    let events: [Event]
    let page: Int
    let perPage: Int
    let total: Int
}

/// Response for guest list
struct GuestListResponse: Codable, Sendable {
    let eventID: UUID
    let guests: [Guest]
    let totalCount: Int
    let checkedInCount: Int
}
