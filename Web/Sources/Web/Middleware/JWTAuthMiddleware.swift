import Foundation
import GuestListShared
import Hummingbird
import Logging

/// Middleware to validate JWT authentication and attach payload to request context
struct JWTAuthMiddleware: RouterMiddleware {
    let authService: AuthService
    let redisService: RedisService
    let logger: Logger

    func handle(_ request: Request, context: AppRequestContext, next: (Request, AppRequestContext) async throws -> Response) async throws -> Response {
        // Extract JWT from Authorization header
        guard let authHeader = request.headers[.authorization],
              authHeader.hasPrefix("Bearer ")
        else {
            logger.warning("Missing or invalid Authorization header", metadata: [
                "path": "\(request.uri.path)",
                "method": "\(request.method)"
            ])
            throw HTTPError(.unauthorized, message: "Missing or invalid Authorization header")
        }

        let token = String(authHeader.dropFirst("Bearer ".count))

        do {
            // Verify JWT signature and expiration
            let payload = try await authService.verifyAccessToken(token)

            // Check if token is blacklisted (revoked during logout)
            let isBlacklisted = try await redisService.isTokenBlacklisted(jti: payload.jti)
            if isBlacklisted {
                logger.warning("Attempt to use blacklisted token", metadata: [
                    "jti": "\(payload.jti)",
                    "user_id": "\(payload.sub)"
                ])
                throw HTTPError(.unauthorized, message: "Token has been revoked")
            }

            logger.debug("JWT validated successfully", metadata: [
                "user_id": "\(payload.sub)",
                "role": "\(payload.role)",
                "path": "\(request.uri.path)"
            ])

            // Create new context with payload attached
            var authenticatedContext = context
            authenticatedContext.payload = payload

            // Call next middleware/handler with authenticated context
            return try await next(request, authenticatedContext)
        } catch let error as AuthError {
            logger.warning("JWT validation failed", metadata: [
                "error": "\(error)",
                "path": "\(request.uri.path)"
            ])

            switch error {
            case .tokenExpired:
                throw HTTPError(.unauthorized, message: "Token expired")
            case .invalidToken:
                throw HTTPError(.unauthorized, message: "Invalid token")
            default:
                throw HTTPError(.unauthorized, message: "Authentication failed")
            }
        } catch {
            logger.error("Unexpected error during JWT validation", metadata: [
                "error": "\(error)",
                "path": "\(request.uri.path)"
            ])
            throw error
        }
    }
}
