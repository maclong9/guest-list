import Hummingbird
import Logging

/// Middleware to log and handle errors
struct ErrorMiddleware<Context: RequestContext>: RouterMiddleware {
    let logger: Logger

    func handle(_ request: Request, context: Context, next: (Request, Context) async throws -> Response) async throws -> Response {
        do {
            return try await next(request, context)
        } catch let error as HTTPError {
            // HTTP errors are already well-formed
            logger.error("HTTP error", metadata: [
                "status": "\(error.status.code)",
                "message": "\(error.body ?? "")",
                "path": "\(request.uri.path)"
            ])
            throw error
        } catch {
            // Unexpected errors - log details
            logger.error("Unexpected error", metadata: [
                "error": "\(error)",
                "type": "\(type(of: error))",
                "path": "\(request.uri.path)",
                "method": "\(request.method)"
            ])

            // Return a generic 500 error
            throw HTTPError(.internalServerError, message: "Internal server error: \(error)")
        }
    }
}
