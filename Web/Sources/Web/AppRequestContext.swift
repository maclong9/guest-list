import Foundation
import GuestListShared
import Hummingbird

/// Custom request context that holds authenticated user information
struct AppRequestContext: RequestContext {
    var coreContext: CoreRequestContextStorage

    /// JWT payload attached by JWTAuthMiddleware (nil for unauthenticated requests)
    var payload: JWTPayload?

    init(source: Source) {
        self.coreContext = .init(source: source)
        self.payload = nil
    }

    /// Require authenticated user, throwing unauthorized error if not present
    func requireIdentity() throws -> JWTPayload {
        guard let payload else {
            throw HTTPError(.unauthorized, message: "Authentication required")
        }
        return payload
    }

    /// Require user to have one of the specified roles
    func requireRole(oneOf roles: Set<UserRole>) throws -> JWTPayload {
        let payload = try requireIdentity()
        guard roles.contains(payload.role) else {
            throw HTTPError(
                .forbidden,
                message: "Insufficient permissions. Required: \(roles.map { $0.rawValue }.joined(separator: ", ")), but user has: \(payload.role.rawValue)"
            )
        }
        return payload
    }

    /// Require user to have access to specific venue
    func requireVenueAccess(_ venueID: UUID) throws -> JWTPayload {
        let payload = try requireIdentity()
        guard payload.venueID == venueID else {
            throw HTTPError(.forbidden, message: "Access denied to this venue's resources")
        }
        return payload
    }
}
