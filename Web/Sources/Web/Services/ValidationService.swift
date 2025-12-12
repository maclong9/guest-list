import Foundation
import GuestListShared
import Hummingbird

/// Service for business logic validation rules
/// Provides validation for event dates, status transitions, and operations
struct ValidationService: Sendable {
    // MARK: - Event Validation

    /// Validate event start and end times
    /// - Parameters:
    ///   - startTime: Event start time
    ///   - endTime: Event end time
    /// - Throws: HTTPError if start time is not before end time
    func validateEventDates(startTime: Date, endTime: Date) throws {
        guard startTime < endTime else {
            throw HTTPError(.badRequest, message: "Event start time must be before end time")
        }
    }

    /// Validate event status transition
    /// - Parameters:
    ///   - from: Current event status
    ///   - to: Desired event status
    /// - Throws: HTTPError if transition is not allowed
    ///
    /// Allowed transitions:
    /// - upcoming → live, cancelled
    /// - live → ended
    /// - ended → (none)
    /// - cancelled → (none)
    func validateStatusTransition(from: EventStatus, to: EventStatus) throws {
        // No transition needed
        if from == to {
            return
        }

        let allowedTransitions: [EventStatus: Set<EventStatus>] = [
            .upcoming: [.live, .cancelled],
            .live: [.ended],
            .ended: [],
            .cancelled: [],
        ]

        guard let allowed = allowedTransitions[from], allowed.contains(to) else {
            throw HTTPError(
                .badRequest,
                message: "Invalid status transition from \(from.rawValue) to \(to.rawValue)"
            )
        }
    }

    /// Check if an event can be modified
    /// - Parameter event: The event to check
    /// - Returns: True if the event can be modified
    ///
    /// Only upcoming events can be modified. Ended and cancelled events are immutable.
    func canModifyEvent(_ event: Event) -> Bool {
        return event.status == .upcoming
    }

    /// Ensure event can be modified, throw error if not
    /// - Parameter event: The event to check
    /// - Throws: HTTPError if event cannot be modified
    func requireModifiableEvent(_ event: Event) throws {
        guard canModifyEvent(event) else {
            throw HTTPError(
                .badRequest,
                message: "Cannot modify \(event.status.rawValue) events. Only upcoming events can be modified."
            )
        }
    }

    // MARK: - Guest Validation

    /// Check if a guest can be checked in for an event
    /// - Parameters:
    ///   - guest: The guest to check in
    ///   - event: The event the guest is attending
    /// - Throws: HTTPError if check-in is not allowed
    ///
    /// Guests can only be checked in for upcoming or live events
    func canCheckInGuest(event: Event) throws {
        guard event.status == .upcoming || event.status == .live else {
            throw HTTPError(
                .badRequest,
                message: "Cannot check in guests for \(event.status.rawValue) events"
            )
        }
    }

    /// Validate event capacity if a capacity limit is set
    /// - Parameters:
    ///   - event: The event to check
    ///   - currentGuestCount: Current number of guests
    /// - Throws: HTTPError if capacity would be exceeded
    func validateCapacity(event: Event, currentGuestCount: Int) throws {
        if let capacity = event.capacity {
            guard currentGuestCount < capacity else {
                throw HTTPError(
                    .badRequest,
                    message: "Event is at capacity (\(capacity) guests)"
                )
            }
        }
    }
}
