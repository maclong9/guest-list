# GuestList Web Server

Hummingbird 2 backend API and WebUI frontend for the GuestList management system.

## Architecture

This server provides:
- **REST API** at `/api/v1/*` (JSON)
- **WebUI Frontend** at `/*` (server-rendered HTML)
- **WebSocket Chat** at `/chat/:eventID` (real-time messaging)

## Quick Start

```bash
# Start services (PostgreSQL + Redis)
make services-up

# Run with hot reload (recommended)
make dev

# Or run manually
cd Web && swift run Web

# Start services (PostgreSQL + Redis via Docker Compose)
cd .. && make services-up

# Test endpoints
curl http://localhost:8080/health
curl http://localhost:8080/api/v1/version
open http://localhost:8080/

# Production testing (full Docker stack)
make services-up-full
```

## Project Structure

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
├── Package.swift              # Swift package manifest
├── Sources/Web/
│   ├── Application.swift      # Main entry point, service & route setup
│   ├── Controllers/           # HTTP request handlers
│   │   ├── AuthController.swift
│   │   ├── VenueController.swift
│   │   ├── EventController.swift
│   │   ├── GuestController.swift
│   │   └── TicketController.swift
│   ├── Services/              # Business logic layer
│   │   ├── AuthService.swift           # JWT & password hashing
│   │   ├── RedisService.swift          # Redis operations
│   │   ├── AuthorizationService.swift  # JWT extraction & role checks
│   │   ├── ValidationService.swift     # Business rule validation
│   │   └── TicketService.swift         # QR code generation & HMAC
│   ├── Middleware/            # Request/response interceptors
│   │   └── JWTAuthMiddleware.swift     # JWT validation
│   └── Migrations/            # Database schema migrations
│       ├── CreateVenues.swift
│       ├── CreateUsers.swift
│       ├── CreateEvents.swift
│       ├── CreateGuests.swift
│       ├── CreateTickets.swift
│       └── CreateMessages.swift
```

## Key Patterns

### 1. Controller Pattern

Controllers handle HTTP requests and return responses. They follow this structure:

```swift
struct MyController: Sendable {
    let fluent: Fluent
    let authorizationService: AuthorizationService
    let logger: Logger

    func addRoutes(to group: RouterGroup<some RequestContext>) {
        group.get(":id", use: getItem)
        group.post(use: createItem)
    }

    @Sendable
    private func getItem(_ request: Request, context: some RequestContext) async throws -> Response {
        // 1. Authenticate
        let payload = try await authorizationService.extractAuthenticatedUser(request)

        // 2. Authorize
        try authorizationService.requireRole(payload, oneOf: [.owner, .admin])

        // 3. Decode request
        let itemID = context.parameters.get("id", as: String.self)

        // 4. Query database (scoped to user's venue)
        let item = try await ItemModel.query(on: fluent.db())
            .filter(\.$venue.$id == payload.venueID)
            .filter(\.$id == itemID)
            .first()

        // 5. Encode response
        return try encodeJSONResponse(item.toDTO())
    }

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
```

### 2. Service Layer

Services encapsulate business logic and are reused across controllers:

**Actor Services** (for mutable state or async operations):
```swift
actor AuthorizationService: Sendable {
    func extractAuthenticatedUser(_ request: Request) async throws -> JWTPayload { }

    // nonisolated for synchronous role checks
    nonisolated func requireRole(_ payload: JWTPayload, oneOf roles: Set<UserRole>) throws { }
    nonisolated func requireVenueAccess(_ payload: JWTPayload, venueID: UUID) throws { }
}
```

**Struct Services** (for pure logic):
```swift
struct ValidationService: Sendable {
    func validateEventDates(startTime: Date, endTime: Date) throws { }
    func validateStatusTransition(from: EventStatus, to: EventStatus) throws { }
}
```

### 3. Multi-Tenant Venue Scoping

All queries are automatically scoped to the authenticated user's venue:

```swift
let events = try await EventModel.query(on: fluent.db())
    .filter(\.$venue.$id == payload.venueID)  // Automatic venue scoping
    .all()
```

### 4. Role-Based Authorization

Authorization flow in handlers:

```swift
// Extract JWT and get user info
let payload = try await authorizationService.extractAuthenticatedUser(request)

// Check role (synchronous - nonisolated method)
try authorizationService.requireRole(payload, oneOf: [.owner, .admin, .staff])

// Check venue access
try authorizationService.requireVenueAccess(payload, venueID: venueID)
```

**Role hierarchy:**
- **Owner**: Full access to all venue resources, can delete events
- **Admin**: Full access except deletion
- **Staff**: Can create/read/update, check-in guests, validate tickets
- **Performer**: Read-only access to own events and guest lists
- **Guest**: Read-only access to own tickets

### 5. Route Registration

Routes are registered in `Application.swift`:

```swift
// Initialize services
let authService = AuthService(jwtSecret: jwtSecret, ...)
let redisService = RedisService(redis: redis, logger: logger)
let authorizationService = AuthorizationService(authService: authService, redisService: redisService)
let validationService = ValidationService()
let ticketService = TicketService(hmacSecret: jwtSecret)

// Initialize controllers
let authController = AuthController(authService: authService, redisService: redisService, fluent: fluent, logger: logger)
let venueController = VenueController(fluent: fluent, authorizationService: authorizationService, logger: logger)
let eventController = EventController(fluent: fluent, authorizationService: authorizationService, validationService: validationService, logger: logger)
let guestController = GuestController(fluent: fluent, authorizationService: authorizationService, validationService: validationService, logger: logger)
let ticketController = TicketController(fluent: fluent, authorizationService: authorizationService, ticketService: ticketService, logger: logger)

// Public routes (no JWT required)
let authGroup = router.group("api/v1/auth")
authController.addRoutes(to: authGroup)

// Protected routes (JWT required)
let jwtMiddleware: JWTAuthMiddleware = .init(authService: authService, redisService: redisService, logger: logger)
let protectedGroup = router.group("api/v1")
    .add(middleware: jwtMiddleware)

let venuesGroup = protectedGroup.group("venues")
venueController.addRoutes(to: venuesGroup)

let eventsGroup = protectedGroup.group("events")
eventController.addRoutes(to: eventsGroup)

let guestsGroup = protectedGroup.group("guests")
guestController.addRoutes(to: guestsGroup)

let ticketsGroup = protectedGroup.group("tickets")
ticketController.addRoutes(to: ticketsGroup)
```

**Note:** Controllers are stored in variables before calling `addRoutes()` to avoid generic type inference issues.

### 6. JWT Authentication Flow

1. **Login** → Receive `accessToken` (24h) + `refreshToken` (30d)
2. **API Request** → Include `Authorization: Bearer <accessToken>`
3. **Middleware** → Validates JWT signature and expiration
4. **Controller** → Extracts user info via `AuthorizationService`
5. **Token Refresh** → Use `/api/v1/auth/refresh` with refresh token
6. **Logout** → Blacklists access token in Redis

### 7. FluentGen Model Access

FluentGen generates Fluent models from shared DTOs. Access patterns:

```swift
// Model has foreign key to venue
eventModel.$venue.id == payload.venueID  // Access FK ID

// Model has enum field (stored as String)
eventModel.status = EventStatus.live.rawValue  // Write enum
EventStatus(rawValue: eventModel.status)       // Read enum

// Convert between Model and DTO
let dto = eventModel.toDTO()
let model = EventModel(from: dto)
```

### 8. Request/Response DTOs

Controllers define DTOs for type-safe request/response handling:

```swift
// Request DTO
struct CreateEventRequest: Codable, Sendable {
    let name: String
    let startTime: Date
    let endTime: Date
}

// Response DTO
struct EventListResponse: Codable, Sendable {
    let events: [Event]
    let page: Int
    let perPage: Int
    let total: Int
}
```

## API Endpoints

### Authentication (Public)
- `POST /api/v1/auth/register` - Register venue with owner user
- `POST /api/v1/auth/login` - Login with email/password
- `POST /api/v1/auth/refresh` - Refresh access token
- `POST /api/v1/auth/logout` - Logout and blacklist token

### Venues (Protected)
- `GET /api/v1/venues/:id` - Get venue details
- `PUT /api/v1/venues/:id` - Update venue (owner/admin)
- `GET /api/v1/venues/:id/events` - Get all venue events

### Events (Protected)
- `POST /api/v1/events` - Create event (owner/admin/staff)
- `GET /api/v1/events?page=1&per_page=20&status=upcoming` - List events (paginated)
- `GET /api/v1/events/:id` - Get event details
- `PUT /api/v1/events/:id` - Update event (owner/admin/staff, upcoming only)
- `DELETE /api/v1/events/:id` - Delete event (owner/admin, upcoming only)
- `GET /api/v1/events/:id/guests` - Get guest list

### Guests (Protected)
- `POST /api/v1/guests` - Add guest to event (owner/admin/staff)
- `GET /api/v1/guests/:id` - Get guest details
- `PUT /api/v1/guests/:id/check-in` - Check in guest (owner/admin/staff, idempotent)

### Tickets (Protected)
- `GET /api/v1/tickets/:id` - Get ticket with guest/event details
- `POST /api/v1/tickets/validate` - Validate QR code with HMAC (owner/admin/staff)
- `POST /api/v1/tickets/generate` - Generate ticket for guest (owner/admin/staff)

## Security

### Password Hashing
- **Algorithm**: Bcrypt with cost factor 12
- **Thread Pool**: Runs on NIOThreadPool to avoid blocking event loop
- **Strength Requirements**: 12+ chars, uppercase, lowercase, number, special char

### JWT Tokens
- **Algorithm**: HMAC-SHA256
- **Access Token**: 24 hours (configurable via `JWT_EXPIRATION_HOURS`)
- **Refresh Token**: 30 days (configurable via `REFRESH_TOKEN_EXPIRATION_DAYS`)
- **JWT ID (jti)**: Unique identifier for token revocation

### Token Management
- **Storage**: Refresh tokens stored in Redis with TTL
- **Rotation**: Refresh token rotates on each use (old token invalidated)
- **Blacklist**: Access tokens blacklisted in Redis on logout
- **Middleware**: JWT validation on all protected routes

### Ticket QR Codes
- **Format**: `ticket:{ticketID}:{eventID}:{guestID}`
- **Signature**: HMAC-SHA256 (same secret as JWT)
- **Offline Validation**: Signature can be validated without database
- **Database Verification**: Confirms current validity state

## Development

### Environment Variables

Required in `.env` file:

```bash
DATABASE_URL=postgres://guestlist:password@localhost:5432/guestlist
REDIS_URL=redis://localhost:6379
JWT_SECRET=your-secret-key-here
JWT_EXPIRATION_HOURS=24
REFRESH_TOKEN_EXPIRATION_DAYS=30
HOST=0.0.0.0
PORT=8080
```

### Adding a New Controller

1. **Create controller file**: `Controllers/MyController.swift`
2. **Define service dependencies** in init
3. **Implement `addRoutes(to:)`** method
4. **Create handler methods** with `@Sendable` attribute
5. **Register in `Application.swift`**:
   ```swift
   let myController = MyController(...)
   let myGroup = protectedGroup.group("my-resource")
   myController.addRoutes(to: myGroup)
   ```

### Adding a New Service

1. **Choose pattern**:
   - `actor` for mutable state or async operations
   - `struct` for pure logic (mark methods as `nonisolated` if needed)
2. **Mark as `Sendable`**
3. **Initialize in `Application.swift`**
4. **Pass to controllers as dependency**

## Testing

```bash
# Run all tests
swift test

# Run specific test
swift test --filter "MyControllerTests"
```

Uses **Swift Testing** framework (@Test, @Suite).

## Dependencies

- **Hummingbird 2**: Swift server framework
- **HummingbirdFluent**: Fluent ORM integration
- **HummingbirdAuth**: Authentication utilities
- **HummingbirdRedis**: Redis client
- **FluentPostgresDriver**: PostgreSQL driver
- **Bcrypt**: Password hashing
- **Crypto**: JWT signing and HMAC
- **WebUI**: Type-safe HTML/CSS generation (future)

## References

- [Hummingbird Documentation](https://docs.hummingbird.codes)
- [Fluent Documentation](https://docs.vapor.codes/fluent/overview/)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
