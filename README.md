<<<<<<< HEAD
# GuestList - Full-Stack Swift Application

A full-stack Swift monorepo for digital guest list management at concert/gig venues. Demonstrates modern Swift development across backend, web frontend, and all Apple platforms.

## Quick Start

```sh
# Setup and build
cd Web && cp .env.example .env && cd ..
make containers-build
make containers-up

# Start developing
make run-web                    # Web server at localhost:8080
open GuestList.xcworkspace      # Platform apps in Xcode
```

### Using the Design System

The project includes a unified design system that works with both SwiftUI and WebUI:

**SwiftUI Example:**
```swift
import SwiftUI
import GuestListShared

struct EventCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing._4.value) {
            Text("Summer Concert Series")
                .typography(size: .xl2, weight: .bold, color: .textPrimary)
            
            Text("July 15, 2025 • 8:00 PM")
                .typography(size: .sm, weight: .medium, color: .textSecondary)
            
            Button("Get Tickets") {
                // Action
            }
            .foregroundColor(.textInverse)
            .padding(._4)
            .backgroundColor(.primary)
            .cornerRadius(.md)
            .shadow(.md)
        }
        .padding(._6)
        .backgroundColor(.backgroundSecondary)
        .cornerRadius(.lg)
    }
}
```

**WebUI Example:**
```swift
import WebUI
import GuestListShared

func eventCard() -> some HTML {
    Division {
        Heading(.two) { "Summer Concert Series" }
            .font(
                size: DesignSystem.Typography.xl2.webUISize,
                weight: DesignSystem.Weight.bold.webUIWeight,
                color: .custom(DesignSystem.Colors.textPrimary.hex)
            )
        
        Paragraph { "July 15, 2025 • 8:00 PM" }
            .font(
                size: DesignSystem.Typography.sm.webUISize,
                weight: DesignSystem.Weight.medium.webUIWeight,
                color: .custom(DesignSystem.Colors.textSecondary.hex)
            )
        
        Button { "Get Tickets" }
            .font(color: .custom(DesignSystem.Colors.textInverse.hex))
            .padding(of: DesignSystem.Spacing._4.webUIValue, at: .all)
            .background(color: .custom(DesignSystem.Colors.primary.hex))
            .rounded(DesignSystem.Radius.md.webUIValue)
            .shadow(DesignSystem.Shadow.md.webUIValue)
    }
    .padding(of: DesignSystem.Spacing._6.webUIValue, at: .all)
    .background(color: .custom(DesignSystem.Colors.backgroundSecondary.hex))
    .rounded(DesignSystem.Radius.lg.webUIValue)
}
```

Both examples produce visually identical results using the same design tokens!

## What It Does

**GuestList** helps venues manage events with:
- **Guest lists** - Track invited guests, ticket purchasers, and arrivals
- **Digital tickets** - QR code tickets with offline validation
- **Live chat** - Real-time messaging via WebSockets
- **Venue dashboard** - Event management with custom theming
- **Event schedules** - Customers view upcoming events, venues manage and edit event details
- **Marketing site** - Feature showcase and pricing pages

## Project Structure

```
GuestList/
├── Shared/                     # Cross-platform Swift package
│   └── Sources/GuestListShared/
│       ├── Models/             # Event, Ticket, Guest, Venue, User, Message
│       ├── Services/           # APIClient, WebSocketService
│       ├── ViewModels/         # Shared business logic
│       └── Utilities/          # Helpers and extensions
│
├── Web/                        # Hummingbird backend + WebUI frontend
│   ├── Containers/             # Container definitions (PostgreSQL, Redis)
│   │   ├── postgres.Containerfile
│   │   ├── redis.Containerfile
│   │   └── redis.conf
│   └── Sources/Web/
│       ├── Application.swift   # Entry point, routing
│       ├── Controllers/        # API handlers
│       ├── Services/           # Business logic
│       ├── Middleware/         # Auth, logging, metrics
│       ├── WebSockets/         # Real-time chat
│       └── Pages/              # Type-safe HTML via WebUI
│
└── Apps/                       # All Apple platform apps
    ├── GuestList.xcodeproj/    # Unified Xcode project (all platforms)
    ├── iOS/                    # iOS app
    │   ├── App/                # Entry point
    │   ├── Screens/            # SwiftUI views
    │   ├── Components/         # Reusable UI
    │   └── Resources/          # Assets, Info.plist
    ├── macOS/                  # macOS app
    │   ├── App/                # Entry point
    │   ├── Screens/            # SwiftUI views
    │   ├── Components/         # Reusable UI
    │   └── Resources/          # Assets, Info.plist
    ├── Watch/                  # watchOS app (embedded in iOS)
    │   ├── App/                # Entry point
    │   ├── Screens/            # Watch views
    │   ├── Components/         # Watch UI components
    │   ├── Complications/      # Watch face complications
    │   └── Resources/          # Assets, Info.plist
    └── Vision/                 # visionOS app (embedded in iOS)
        ├── App/                # Entry point
        ├── Screens/            # Vision views
        ├── Components/         # Vision UI components
        └── Resources/          # Assets, Info.plist
```

## Technology Stack

- **Backend**: Hummingbird 2, PostgreSQL, Redis, WebSockets, JWT auth
- **Frontend**: [WebUI](https://github.com/maclong9/web-ui) - Type-safe HTML/CSS/JS in Swift
- **Shared**: Swift 6.2+, async/await, actors, Sendable
- **Platforms**: SwiftUI on iOS 17+ (with embedded watchOS 10+ & visionOS 1+ apps), macOS 14+
- **Tools**: swift-format, container runtime (apple/container compatible)

## Development

### Common Commands

```sh
make help              # List all commands

# Development
make format            # Format code (run before commits)
make lint              # Check formatting

# Building
make build             # Build everything
make build-shared      # Build Shared package only
make build-web         # Build Web server only
make build-xcode       # Build platform apps only

# Testing
make test              # Run all tests
make test-shared       # Test Shared package only
make test-web          # Test Web server only
make test-xcode        # Test platform apps only

# Running
make run-web           # Start server (localhost:8080)

# Containers
make containers-build  # Build container images
make containers-up     # Start PostgreSQL + Redis
make containers-down   # Stop containers
make containers-logs   # View logs
make containers-clean  # Remove containers and volumes

# Projects
make clean             # Clean build artifacts
```

## Architecture

### Shared Models

Domain models in `Shared/` are used by all platforms:

```swift
struct Event: Codable, Identifiable, Sendable {
    let id: UUID
    let venueID: UUID
    let name: String
    let startTime: Date
    let endTime: Date
    let status: EventStatus  // .upcoming, .live, .ended
}
```

All models conform to `Codable` and `Sendable` for Swift 6 concurrency.

### API Client

Platform apps use shared `APIClient` actor:

```swift
actor APIClient {
    func fetchEvents() async throws -> [Event]
    func createEvent(_ event: Event) async throws -> Event
    func checkInGuest(_ id: UUID) async throws -> Guest
}
```

### API Endpoints

**Authentication:**
```
POST   /api/v1/auth/signup         # Register new venue
POST   /api/v1/auth/login          # Login (venue/staff)
POST   /api/v1/auth/refresh        # Refresh JWT token
POST   /api/v1/auth/logout         # Logout
```

**Events:**
```
GET    /api/v1/events              # List events (with filters)
POST   /api/v1/events              # Create event
GET    /api/v1/events/:id          # Get event details
PUT    /api/v1/events/:id          # Update event
DELETE /api/v1/events/:id          # Delete event
GET    /api/v1/events/:id/guests   # Get guest list
```

**Guests:**
```
GET    /api/v1/guests/:id          # Get guest details
PUT    /api/v1/guests/:id          # Update guest info
PUT    /api/v1/guests/:id/check-in # Check in guest
DELETE /api/v1/guests/:id          # Remove from guest list
```

**Tickets:**
```
POST   /api/v1/tickets             # Generate ticket
GET    /api/v1/tickets/:id         # Get ticket details
POST   /api/v1/tickets/validate    # Validate ticket QR code
```

**Venues:**
```
GET    /api/v1/venues/:id          # Get venue details
PUT    /api/v1/venues/:id          # Update venue settings
GET    /api/v1/venues/:id/events   # List venue's events
```

**WebSocket:**
```
WS     /chat/:eventID              # Real-time event chat
```

## Database

PostgreSQL schema:
- `venues` - Customers (free/paid tiers)
- `events` - Event details and timing
- `guests` - Guest lists with check-in status
- `tickets` - QR codes and validation
- `messages` - Chat messages

Redis cache:
- Session data (JWT tokens)
- Rate limiting counters
- Chat presence
- Validated ticket cache

## Future Extensions

### Ticket Sales Platform
Potential extension to allow venues to sell tickets directly through the platform:
- **Payment processing** - Stripe/PayPal integration
- **Ticket marketplace** - Public event listings and discovery
- **Revenue sharing** - Small platform fee (e.g., 2-5% per ticket)
- **Payout system** - Automated venue payouts
- **Refund handling** - Customer refund requests and processing
- **Analytics** - Sales tracking and revenue reports

This would transform GuestList from a guest management tool into a complete ticketing solution.

## Adding Features

1. **Define model** in `Shared/Sources/GuestListShared/Models/`
2. **Add API endpoint** in `Web/Sources/Web/Controllers/`
3. **Update APIClient** in `Shared/Sources/GuestListShared/Services/`
4. **Build UI** in platform apps or WebUI pages

## Implementation Status

**✅ Complete:**
- Monorepo structure with shared code
- Multi-platform Xcode project (iOS, macOS, watchOS, visionOS)
- Container setup (PostgreSQL, Redis)
- CI/CD pipelines
- Code formatting and linting

**🚧 In Progress:**
- Database integration (PostgresNIO)
- Redis caching (HummingbirdRedis)
- JWT authentication
- API endpoints
- WebSocket chat
- WebUI frontend pages
- Platform app features
- Customer event schedule views (upcoming events)
- Venue dashboard for event management and editing

See full status in implementation checklist above.

## Security

- JWT authentication with refresh tokens
- Role-based access control (venue owner, staff, performer, guest)
- HMAC-signed QR codes to prevent ticket forgery
- Rate limiting via Redis
- TLS in transit, encryption at rest

See [SECURITY.md](SECURITY.md) for details.

## Contributing

```sh
git clone https://github.com/your-username/GuestList.git
cd Web && cp .env.example .env && cd ..
make containers-build && make containers-up
make build && make test
make format
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Resources

- [Hummingbird](https://hummingbird.codes/) - Swift web framework
- [WebUI](https://github.com/maclong9/web-ui) - Type-safe HTML in Swift
- [apple/container](https://github.com/apple/container) - Container runtime

## License

Apache 2.0 - See [LICENSE](LICENSE) file.

Educational project demonstrating full-stack Swift development.
||||||| (empty tree)
=======
# GuestList - Full-Stack Swift Application

A full-stack Swift monorepo for digital guest list management at concert/gig venues. Demonstrates modern Swift development across backend, web frontend, and all Apple platforms.

## Quick Start

```sh
# Install dependencies
brew bundle                     # Install watchexec, OrbStack, etc.

# Setup environment
cd Web && cp .env.example .env && cd ..

# Start developing (with hot reload)
make dev                        # Starts services + web server with auto-restart

# Or manually
make services-up                # Start PostgreSQL + Redis
make run-web                    # Start web server at localhost:8080

# Platform apps
open GuestList.xcworkspace      # iOS, macOS, watchOS, visionOS in Xcode
```

### Using the Design System

The project includes a unified design system that works with both SwiftUI and WebUI:

**SwiftUI Example:**
```swift
import SwiftUI
import GuestListShared

struct EventCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing._4.value) {
            Text("Summer Concert Series")
                .typography(size: .xl2, weight: .bold, color: .textPrimary)
            
            Text("July 15, 2025 • 8:00 PM")
                .typography(size: .sm, weight: .medium, color: .textSecondary)
            
            Button("Get Tickets") {
                // Action
            }
            .foregroundColor(.textInverse)
            .padding(._4)
            .backgroundColor(.primary)
            .cornerRadius(.md)
            .shadow(.md)
        }
        .padding(._6)
        .backgroundColor(.backgroundSecondary)
        .cornerRadius(.lg)
    }
}
```

**WebUI Example:**
```swift
import WebUI
import GuestListShared

func eventCard() -> some HTML {
    Division {
        Heading(.two) { "Summer Concert Series" }
            .font(
                size: DesignSystem.Typography.xl2.webUISize,
                weight: DesignSystem.Weight.bold.webUIWeight,
                color: .custom(DesignSystem.Colors.textPrimary.hex)
            )
        
        Paragraph { "July 15, 2025 • 8:00 PM" }
            .font(
                size: DesignSystem.Typography.sm.webUISize,
                weight: DesignSystem.Weight.medium.webUIWeight,
                color: .custom(DesignSystem.Colors.textSecondary.hex)
            )
        
        Button { "Get Tickets" }
            .font(color: .custom(DesignSystem.Colors.textInverse.hex))
            .padding(of: DesignSystem.Spacing._4.webUIValue, at: .all)
            .background(color: .custom(DesignSystem.Colors.primary.hex))
            .rounded(DesignSystem.Radius.md.webUIValue)
            .shadow(DesignSystem.Shadow.md.webUIValue)
    }
    .padding(of: DesignSystem.Spacing._6.webUIValue, at: .all)
    .background(color: .custom(DesignSystem.Colors.backgroundSecondary.hex))
    .rounded(DesignSystem.Radius.lg.webUIValue)
}
```

Both examples produce visually identical results using the same design tokens!

## What It Does

**GuestList** helps venues manage events with:
- **Guest lists** - Track invited guests, ticket purchasers, and arrivals
- **Digital tickets** - QR code tickets with offline validation
- **Live chat** - Real-time messaging via WebSockets
- **Venue dashboard** - Event management with custom theming
- **Event schedules** - Customers view upcoming events, venues manage and edit event details
- **Marketing site** - Feature showcase and pricing pages

## Project Structure

```
GuestList/
├── Shared/                     # Cross-platform Swift package
│   └── Sources/GuestListShared/
│       ├── Models/             # Event, Ticket, Guest, Venue, User, Message
│       ├── Services/           # APIClient, WebSocketService
│       ├── ViewModels/         # Shared business logic
│       └── Utilities/          # Helpers and extensions
│
├── Web/                        # Hummingbird backend + WebUI frontend
│   └── Sources/Web/
│       ├── Application.swift   # Entry point, routing
│       ├── Controllers/        # API handlers
│       ├── Services/           # Business logic
│       ├── Middleware/         # Auth, logging, metrics
│       ├── WebSockets/         # Real-time chat
│       └── Pages/              # Type-safe HTML via WebUI
│
└── Apps/                       # All Apple platform apps
    ├── GuestList.xcodeproj/    # Unified Xcode project (all platforms)
    ├── iOS/                    # iOS app
    │   ├── App/                # Entry point
    │   ├── Screens/            # SwiftUI views
    │   ├── Components/         # Reusable UI
    │   └── Resources/          # Assets, Info.plist
    ├── macOS/                  # macOS app
    │   ├── App/                # Entry point
    │   ├── Screens/            # SwiftUI views
    │   ├── Components/         # Reusable UI
    │   └── Resources/          # Assets, Info.plist
    ├── Watch/                  # watchOS app (embedded in iOS)
    │   ├── App/                # Entry point
    │   ├── Screens/            # Watch views
    │   ├── Components/         # Watch UI components
    │   ├── Complications/      # Watch face complications
    │   └── Resources/          # Assets, Info.plist
    └── Vision/                 # visionOS app (embedded in iOS)
        ├── App/                # Entry point
        ├── Screens/            # Vision views
        ├── Components/         # Vision UI components
        └── Resources/          # Assets, Info.plist
```

## Technology Stack

- **Backend**: Hummingbird 2, Fluent ORM, PostgreSQL, Redis, WebSockets, JWT auth
- **Frontend**: [WebUI](https://github.com/maclong9/web-ui) - Type-safe HTML/CSS/JS in Swift
- **Shared**: Swift 6.2+, async/await, actors, Sendable
- **Platforms**: SwiftUI on iOS 17+ (with embedded watchOS 10+ & visionOS 1+ apps), macOS 14+
- **Tools**: Swift Package Manager, Docker Compose (via OrbStack), watchexec (hot reload)

## Development

### Common Commands

```sh
make help              # List all commands

# Development
make format            # Format code (run before commits)
make lint              # Check formatting

# Building
make build             # Build everything
make build-shared      # Build Shared package only
make build-web         # Build Web server only
make build-xcode       # Build platform apps only

# Testing
make test              # Run all tests
make test-shared       # Test Shared package only
make test-web          # Test Web server only
make test-xcode        # Test platform apps only

# Running
make run-web           # Start server (localhost:8080)

# Services (Docker Compose)
make services-up       # Start PostgreSQL + Redis
make services-up-full  # Start databases + web server (production test)
make services-down     # Stop services
make services-logs     # View logs
make services-restart  # Restart services
make services-clean    # Remove services and volumes

# Development
make dev               # Start with hot reload (recommended)
make run-web           # Start server without hot reload

# Projects
make clean             # Clean build artifacts
```

## Architecture

### Shared Models

Domain models in `Shared/` are used by all platforms:

```swift
struct Event: Codable, Identifiable, Sendable {
    let id: UUID
    let venueID: UUID
    let name: String
    let startTime: Date
    let endTime: Date
    let status: EventStatus  // .upcoming, .live, .ended
}
```

All models conform to `Codable` and `Sendable` for Swift 6 concurrency.

### API Client

Platform apps use shared `APIClient` actor:

```swift
actor APIClient {
    func fetchEvents() async throws -> [Event]
    func createEvent(_ event: Event) async throws -> Event
    func checkInGuest(_ id: UUID) async throws -> Guest
}
```

### API Endpoints

**Authentication:**
```
POST   /api/v1/auth/signup         # Register new venue
POST   /api/v1/auth/login          # Login (venue/staff)
POST   /api/v1/auth/refresh        # Refresh JWT token
POST   /api/v1/auth/logout         # Logout
```

**Events:**
```
GET    /api/v1/events              # List events (with filters)
POST   /api/v1/events              # Create event
GET    /api/v1/events/:id          # Get event details
PUT    /api/v1/events/:id          # Update event
DELETE /api/v1/events/:id          # Delete event
GET    /api/v1/events/:id/guests   # Get guest list
```

**Guests:**
```
GET    /api/v1/guests/:id          # Get guest details
PUT    /api/v1/guests/:id          # Update guest info
PUT    /api/v1/guests/:id/check-in # Check in guest
DELETE /api/v1/guests/:id          # Remove from guest list
```

**Tickets:**
```
POST   /api/v1/tickets             # Generate ticket
GET    /api/v1/tickets/:id         # Get ticket details
POST   /api/v1/tickets/validate    # Validate ticket QR code
```

**Venues:**
```
GET    /api/v1/venues/:id          # Get venue details
PUT    /api/v1/venues/:id          # Update venue settings
GET    /api/v1/venues/:id/events   # List venue's events
```

**WebSocket:**
```
WS     /chat/:eventID              # Real-time event chat
```

## Database

PostgreSQL schema:
- `venues` - Customers (free/paid tiers)
- `events` - Event details and timing
- `guests` - Guest lists with check-in status
- `tickets` - QR codes and validation
- `messages` - Chat messages

Redis cache:
- Session data (JWT tokens)
- Rate limiting counters
- Chat presence
- Validated ticket cache

## Future Extensions

### Enhanced Authentication Methods
Planned improvements to the authentication system:
- **Magic Email Sign-in** - Passwordless authentication via email links
- **Sign in with Apple** - Native Apple ID integration for iOS/macOS apps
- **Sign in with Google** - OAuth integration for cross-platform access

These additions will provide users with more convenient and secure authentication options beyond traditional username/password login.

### Ticket Sales Platform
Potential extension to allow venues to sell tickets directly through the platform:
- **Payment processing** - Stripe/PayPal integration
- **Ticket marketplace** - Public event listings and discovery
- **Revenue sharing** - Small platform fee (e.g., 2-5% per ticket)
- **Payout system** - Automated venue payouts
- **Refund handling** - Customer refund requests and processing
- **Analytics** - Sales tracking and revenue reports

This would transform GuestList from a guest management tool into a complete ticketing solution.

## Adding Features

1. **Define model** in `Shared/Sources/GuestListShared/Models/`
2. **Add API endpoint** in `Web/Sources/Web/Controllers/`
3. **Update APIClient** in `Shared/Sources/GuestListShared/Services/`
4. **Build UI** in platform apps or WebUI pages

## Implementation Status

**✅ Complete:**
- Monorepo structure with shared code
- Multi-platform Xcode project (iOS, macOS, watchOS, visionOS)
- Docker Compose setup (PostgreSQL, Redis)
- CI/CD pipelines
- Code formatting and linting

**🚧 In Progress:**
- Database integration (PostgresNIO)
- Redis caching (HummingbirdRedis)
- JWT authentication
- API endpoints
- WebSocket chat
- WebUI frontend pages
- Platform app features
- Customer event schedule views (upcoming events)
- Venue dashboard for event management and editing

See full status in implementation checklist above.

## Security

- JWT authentication with refresh tokens
- Role-based access control (venue owner, staff, performer, guest)
- HMAC-signed QR codes to prevent ticket forgery
- Rate limiting via Redis
- TLS in transit, encryption at rest

See [SECURITY.md](SECURITY.md) for details.

## Contributing

```sh
git clone https://github.com/your-username/GuestList.git
brew bundle                     # Install dependencies
cd Web && cp .env.example .env && cd ..
make services-up
make build && make test
make format
```

## Prerequisites

- **macOS** 14.0+ (for Xcode and platform apps)
- **Xcode** 16.0+ (includes Swift 6.2+)
- **OrbStack** or Docker Desktop (for services)
- **watchexec** (optional, for hot reload): `brew install watchexec`

Install all development dependencies:
```sh
brew bundle
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Resources

- [Hummingbird](https://hummingbird.codes/) - Swift web framework
- [WebUI](https://github.com/maclong9/web-ui) - Type-safe HTML in Swift
- [Docker Compose](https://docs.docker.com/compose/) - Container orchestration (via OrbStack or Docker Desktop)

## License

Apache 2.0 - See [LICENSE](LICENSE) file.

Educational project demonstrating full-stack Swift development.
>>>>>>> b75037e (Project initialized 🚀)
