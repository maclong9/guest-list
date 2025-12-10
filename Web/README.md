# GuestList Web

Unified web server using Hummingbird for both API and frontend (WebUI-generated) routes.

## Architecture

This server handles:
- **Frontend Routes** (`/*`) - WebUI-generated HTML pages served by Hummingbird
- **API Routes** (`/api/v1/*`) - REST API endpoints
- **WebSocket** (`/chat/:eventID`) - Real-time chat (coming soon)

## Quick Start

```sh
# Build the server
swift build

# Run the server (starts on http://localhost:8080)
swift run Web

# Run tests (using Swift Testing)
swift test

# Build and start containers (PostgreSQL + Redis)
cd .. && make containers-build && make containers-up

# Test endpoints
curl http://localhost:8080/health
curl http://localhost:8080/api/v1/version
open http://localhost:8080/
```

## Container Development

All services use [apple/container](https://github.com/apple/container) with Containerfiles.

### Container Files

- `Containerfile` - Swift web server
- `Containers/postgres.Containerfile` - PostgreSQL database
- `Containers/redis.Containerfile` - Redis cache
- `Containers/redis.conf` - Redis configuration

### Quick Start

```sh
# Copy environment template (first time only)
cp .env.example .env

# Build images (first time or after Containerfile changes)
cd .. && make containers-build

# Start PostgreSQL + Redis
cd .. && make containers-up

# View logs
cd .. && make containers-logs

# Stop containers
cd .. && make containers-down

# Clean everything
cd .. && make containers-clean
```

### Container Services

**PostgreSQL** (Port 5432)
- Image: `guestlist-postgres`
- Volume: `guestlist-postgres-data`
- Health check enabled

**Redis** (Port 6379)
- Image: `guestlist-redis`
- Volume: `guestlist-redis-data`
- Password-protected
- Health check enabled

**Swift Server** (Port 8080)
- Image: `guestlist-web`
- Runs as non-root user
- Health check endpoint: `/health`

### Development Workflow

```sh
# 1. Build images
make containers-build

# 2. Start services
make containers-up

# 3. Run Swift server locally (connects to containers)
swift run Web

# 4. Or run entire stack in containers
container run -p 8080:8080 --env-file .env guestlist-web
```

### Connecting from Platform Apps

Configure API client in `Shared/Sources/GuestListShared/Services/APIClient.swift`:
```swift
let baseURL = URL(string: "http://localhost:8080")!
```

For device testing, replace `localhost` with your Mac's IP address.

### Container Management

```sh
# Connect to PostgreSQL
container exec -it guestlist-postgres psql -U guestlist

# Connect to Redis
container exec -it guestlist-redis redis-cli

# View logs
container logs guestlist-postgres
container logs guestlist-redis

# Restart a service
container restart guestlist-postgres
```

### Database Migrations

```sh
# Run migrations (once implemented)
swift run Web migrate

# Reset database
make containers-clean
make containers-build
make containers-up
swift run Web migrate
```

## Development

### Project Structure
```
Web/
├── Sources/Web/
│   ├── Application.swift       # Main entry point & routing
│   │
│   ├── API (Backend)
│   ├── Controllers/            # API endpoint handlers
│   ├── Services/               # Business logic
│   ├── Middleware/             # Request/response middleware
│   ├── WebSockets/             # WebSocket handlers
│   ├── Jobs/                   # Background jobs
│   ├── Migrations/             # Database migrations
│   ├── DTOs/                   # Data transfer objects
│   │
│   └── Frontend (WebUI)
│       ├── Pages/              # WebUI page components
│       ├── Components/         # Reusable UI components
│       ├── Styles/             # Type-safe CSS
│       └── Themes/             # Per-venue theming
│
├── Tests/WebTests/             # Tests using Swift Testing
└── Resources/
    └── Protos/                 # Protocol Buffer definitions
```

### Routing Strategy

```swift
// API routes (JSON)
router.group("api/v1") { api in
    api.group("events") { ... }
    api.group("guests") { ... }
    api.group("tickets") { ... }
    api.group("auth") { ... }
}

// Frontend routes (HTML via WebUI)
router.get("**") { request, context in
    // Render WebUI pages based on request path
    return renderPage(for: request.path)
}
```

## API Endpoints

**Health & Version**
```
GET /health                    # Health check
GET /api/v1/version            # API version
```

**Events**
```
GET    /api/v1/events          # List events
POST   /api/v1/events          # Create event
GET    /api/v1/events/:id      # Get event
PUT    /api/v1/events/:id      # Update event
DELETE /api/v1/events/:id      # Delete event
```

**Guests**
```
GET    /api/v1/events/:id/guests   # List guests
POST   /api/v1/guests              # Add guest
PUT    /api/v1/guests/:id/check-in # Check in
DELETE /api/v1/guests/:id          # Remove guest
```

**Tickets**
```
GET    /api/v1/tickets/:id         # Get ticket
POST   /api/v1/tickets/validate    # Validate
POST   /api/v1/tickets/generate    # Generate
```

**Auth**
```
POST   /api/v1/auth/register       # Register venue
POST   /api/v1/auth/login          # Login
POST   /api/v1/auth/refresh        # Refresh token
POST   /api/v1/auth/logout         # Logout
```

**WebSocket**
```
WS     /chat/:eventID              # Real-time chat
```

## Frontend Pages

All pages served as HTML via WebUI:
- `/` - Landing page
- `/features` - Feature descriptions
- `/pricing` - Pricing tiers
- `/dashboard` - Venue dashboard (authenticated)
- `/events` - Event management
- `/events/:id` - Event details
- `/events/:id/guests` - Guest list
- `/events/:id/chat` - Live chat
- `/tickets/:id` - Ticket display

## Testing

This project uses **Swift Testing** (the modern testing framework):

```swift
import Testing
@testable import Web

@Suite("Web Server Tests")
struct WebTests {
    @Test("Server initializes")
    func testServerInitialization() {
        #expect(true)
    }
}
```

## WebUI Integration

WebUI generates HTML/CSS/JS that Hummingbird serves directly:

1. **Define pages** in `Sources/Web/Pages/`
2. **Render in routes** - `renderPage(for: request.path)`
3. **Type-safe HTML** - No string templates or string escapes for js & css
4. **SSR by default** - Better SEO, faster initial load

## Next Steps

1.  ✅ Set up basic routing (API + Frontend)
2.  ⬜ Implement WebUI page rendering
3.  ⬜ Create database migrations
4.  ⬜ Implement authentication (JWT)
5.  ⬜ Add event management endpoints
6.  ⬜ Add guest list endpoints
7.  ⬜ Add ticket generation/validation
8.  ⬜ Implement WebSocket chat
9.  ⬜ Build WebUI pages (marketing, dashboard)
10. ⬜ Add per-venue theming

See the main README.md for the full implementation plan.
