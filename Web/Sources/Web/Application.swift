<<<<<<< HEAD
import Hummingbird
import Logging

@main
struct GuestListApp {
    static func main() async throws {
        let logger = Logger(label: "com.guestlist.web")

        let router = Router()

        // Health check
        router.get("health") { _, _ in
            logger.info("Health check requested")
            return Response(
                status: .ok,
                headers: [.contentType: "application/json"],
                body: .init(byteBuffer: .init(string: "{\"status\":\"healthy\",\"service\":\"guestlist-web\"}"))
            )
        }

        // API routes (v1)
        router.get("api/v1/version") { _, _ in
            Response(
                status: .ok,
                headers: [.contentType: "application/json"],
                body: .init(byteBuffer: .init(string: "{\"version\":\"1.0.0\"}"))
            )
        }

        // TODO: Add API endpoints
        // GET    /api/v1/events
        // POST   /api/v1/events
        // GET    /api/v1/events/:id
        // PUT    /api/v1/events/:id
        // DELETE /api/v1/events/:id
        //
        // GET    /api/v1/events/:id/guests
        // POST   /api/v1/guests
        // PUT    /api/v1/guests/:id/check-in
        //
        // GET    /api/v1/tickets/:id
        // POST   /api/v1/tickets/validate
        // POST   /api/v1/tickets/generate
        //
        // POST   /api/v1/auth/register
        // POST   /api/v1/auth/login
        // POST   /api/v1/auth/refresh
        // POST   /api/v1/auth/logout

        // Frontend routes (WebUI-generated HTML)
        // Catch-all for frontend routes - should be last
        router.get("**") { _, _ in
            // TODO: Implement WebUI page rendering based on request path
            // For now, return a simple HTML response
            let html = """
                <!DOCTYPE html>
                <html lang="en">
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>GuestList - Digital Guest List Management</title>
                    <style>
                        * { margin: 0; padding: 0; box-sizing: border-box; }
                        body {
                            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                            max-width: 800px;
                            margin: 0 auto;
                            padding: 2rem;
                            line-height: 1.6;
                            color: #1f2937;
                        }
                        header { margin-bottom: 2rem; }
                        h1 { color: #2563eb; font-size: 2.5rem; margin-bottom: 0.5rem; }
                        h2 { color: #374151; margin: 1.5rem 0 1rem; }
                        section { margin-bottom: 2rem; }
                        .features { list-style: none; padding: 0; }
                        .features li { padding: 0.75rem 0; border-bottom: 1px solid #e5e7eb; }
                        .features li:last-child { border-bottom: none; }
                        code { background: #f3f4f6; padding: 0.25rem 0.5rem; border-radius: 0.25rem; font-family: monospace; }
                        footer { margin-top: 3rem; padding-top: 2rem; border-top: 1px solid #e5e7eb; color: #6b7280; font-size: 0.875rem; }
                    </style>
                </head>
                <body>
                    <header>
                        <h1>📋 GuestList</h1>
                        <p>Digital Guest List Management for Venues</p>
                    </header>
                    <main>
                        <section>
                            <h2>Welcome</h2>
                            <p>GuestList helps venues manage guest lists, scan tickets, and engage with attendees in real-time.</p>
                        </section>
                        <section>
                            <h2>Features</h2>
                            <ul class="features">
                                <li>📋 <strong>Guest List Management</strong> - Track invited guests and arrivals</li>
                                <li>🎫 <strong>Digital Tickets</strong> - Scannable QR codes with offline validation</li>
                                <li>💬 <strong>Live Chat</strong> - Real-time messaging for events</li>
                                <li>🎨 <strong>Custom Theming</strong> - Per-venue branding</li>
                            </ul>
                        </section>
                        <section>
                            <h2>API</h2>
                            <p>API available at <code>/api/v1/*</code></p>
                        </section>
                    </main>
                    <footer>
                        <p>© 2025 GuestList. Built with Swift, Hummingbird, and WebUI.</p>
                    </footer>
                </body>
                </html>
                """

            return Response(
                status: .ok,
                headers: [.contentType: "text/html; charset=utf-8"],
                body: .init(byteBuffer: .init(string: html))
            )
        }

        // Build and run the application
        var app = Application(router: router)
        app.logger = logger

        logger.info("Starting GuestList web server on http://localhost:8080")
        logger.info("  - Frontend: http://localhost:8080/")
        logger.info("  - API: http://localhost:8080/api/v1/")
        logger.info("  - Health: http://localhost:8080/health")

        try await app.runService()
    }
}
||||||| (empty tree)
=======
import Fluent
import FluentPostgresDriver
import Foundation
import Hummingbird
import HummingbirdFluent
import Logging

@main
struct GuestListApp {
    static func main() async throws {
        let logger = Logger(label: "com.guestlist.web")

        // Configure Fluent with HummingbirdFluent
        let fluent = Fluent(logger: logger)

        // Get database URL from environment
        guard let databaseURL = ProcessInfo.processInfo.environment["DATABASE_URL"] else {
            logger.error("DATABASE_URL environment variable not set")
            throw ApplicationError.missingDatabaseURL
        }

        // Configure PostgreSQL
        try fluent.databases.use(.postgres(url: databaseURL), as: .psql)

        // Add migrations
        await fluent.migrations.add(CreateVenues())
        await fluent.migrations.add(CreateUsers())
        await fluent.migrations.add(CreateEvents())
        await fluent.migrations.add(CreateGuests())
        await fluent.migrations.add(CreateTickets())
        await fluent.migrations.add(CreateMessages())

        // Run migrations
        try await fluent.migrate()

        logger.info("Database migrations completed successfully")

        let router = Router()

        // Health check
        router.get("health") { _, _ in
            logger.info("Health check requested")
            return Response(
                status: .ok,
                headers: [.contentType: "application/json"],
                body: .init(byteBuffer: .init(string: "{\"status\":\"healthy\",\"service\":\"guestlist-web\"}"))
            )
        }

        // API routes (v1)
        router.get("api/v1/version") { _, _ in
            Response(
                status: .ok,
                headers: [.contentType: "application/json"],
                body: .init(byteBuffer: .init(string: "{\"version\":\"1.0.0\"}"))
            )
        }

        // TODO: Add API endpoints
        // EventController
        // GET    /api/v1/events
        // POST   /api/v1/events
        // GET    /api/v1/events/:id
        // PUT    /api/v1/events/:id
        // DELETE /api/v1/events/:id
        // GET    /api/v1/events/:id/guests
        //
        // GuestController
        // POST   /api/v1/guests
        // PUT    /api/v1/guests/:id/check-in
        //
        // TicketController
        // GET    /api/v1/tickets/:id
        // POST   /api/v1/tickets/validate
        // POST   /api/v1/tickets/generate
        //
        // AuthController
        // POST   /api/v1/auth/register
        // POST   /api/v1/auth/login
        // POST   /api/v1/auth/refresh
        // POST   /api/v1/auth/logout

        // Frontend routes (WebUI-generated HTML)
        // Catch-all for frontend routes - should be last
        // WebController to replace hardcoded below
        router.get("**") { _, _ in
            // TODO: Implement WebUI page rendering based on request path
            // For now, return a simple HTML response
            let html = """
                <!DOCTYPE html>
                <html lang="en">
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>GuestList - Digital Guest List Management</title>
                    <style>
                        * { margin: 0; padding: 0; box-sizing: border-box; }
                        body {
                            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                            max-width: 800px;
                            margin: 0 auto;
                            padding: 2rem;
                            line-height: 1.6;
                            color: #1f2937;
                        }
                        header { margin-bottom: 2rem; }
                        h1 { color: #2563eb; font-size: 2.5rem; margin-bottom: 0.5rem; }
                        h2 { color: #374151; margin: 1.5rem 0 1rem; }
                        section { margin-bottom: 2rem; }
                        .features { list-style: none; padding: 0; }
                        .features li { padding: 0.75rem 0; border-bottom: 1px solid #e5e7eb; }
                        .features li:last-child { border-bottom: none; }
                        code { background: #f3f4f6; padding: 0.25rem 0.5rem; border-radius: 0.25rem; font-family: monospace; }
                        footer { margin-top: 3rem; padding-top: 2rem; border-top: 1px solid #e5e7eb; color: #6b7280; font-size: 0.875rem; }
                    </style>
                </head>
                <body>
                    <header>
                        <h1>📋 GuestList</h1>
                        <p>Digital Guest List Management for Venues</p>
                    </header>
                    <main>
                        <section>
                            <h2>Welcome</h2>
                            <p>GuestList helps venues manage guest lists, scan tickets, and engage with attendees in real-time.</p>
                        </section>
                        <section>
                            <h2>Features</h2>
                            <ul class="features">
                                <li>📋 <strong>Guest List Management</strong> - Track invited guests and arrivals</li>
                                <li>🎫 <strong>Digital Tickets</strong> - Scannable QR codes with offline validation</li>
                                <li>💬 <strong>Live Chat</strong> - Real-time messaging for events</li>
                                <li>🎨 <strong>Custom Theming</strong> - Per-venue branding</li>
                            </ul>
                        </section>
                        <section>
                            <h2>API</h2>
                            <p>API available at <code>/api/v1/*</code></p>
                        </section>
                    </main>
                    <footer>
                        <p>© 2025 GuestList. Built with Swift, Hummingbird, and WebUI.</p>
                    </footer>
                </body>
                </html>
                """

            return Response(
                status: .ok,
                headers: [.contentType: "text/html; charset=utf-8"],
                body: .init(byteBuffer: .init(string: html))
            )
        }

        // Build and run the application
        var app = Application(router: router)
        app.logger = logger

        logger.info("Starting GuestList web server on http://localhost:8080")
        logger.info("  - Frontend: http://localhost:8080/")
        logger.info("  - API: http://localhost:8080/api/v1/")
        logger.info("  - Health: http://localhost:8080/health")

        try await app.runService()
    }
}

enum ApplicationError: Error {
    case missingDatabaseURL
    case databaseConnectionFailed
}
>>>>>>> b75037e (Project initialized 🚀)
