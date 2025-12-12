# GuestList TODO

## Current Development Status

### ✅ Completed

**Infrastructure & DevOps:**
- ✅ Full-stack Swift architecture (Shared, Web, iOS, macOS, watchOS, visionOS)
- ✅ FluentGen macros for automatic Fluent model generation
- ✅ Docker Compose with PostgreSQL + Redis
- ✅ Database migrations with foreign key relationships
- ✅ **Containerized development with hot reload** (`make services-up-dev`)
- ✅ Native development with hot reload (`make dev`)
- ✅ Production-ready Dockerfile (`make services-up-full`)
- ✅ Comprehensive Makefile and documentation
- ✅ Cross-platform DesignSystem (works on Linux + Apple platforms)

**Backend API:**
- ✅ Database integration (PostgresNIO + Fluent)
- ✅ Redis integration (HummingbirdRedis) with RedisService for token management
- ✅ JWT authentication service (HMAC-SHA256) with jti for token revocation
- ✅ Bcrypt password hashing with NIOThreadPool (cost factor 12)
- ✅ Password strength validation (12 chars, uppercase, lowercase, number, special char)
- ✅ Cross-platform random token generation
- ✅ AuthController (register, login, refresh with rotation, logout with blacklisting)
- ✅ JWT authentication middleware for protected routes
- ✅ Refresh token storage in Redis with TTL (30 days)
- ✅ Refresh token rotation for enhanced security
- ✅ Access token blacklisting in Redis for logout
- ✅ Health check endpoint
- ✅ Error handling middleware

**Data Models:**
- ✅ User model with password hashing support
- ✅ Venue model
- ✅ Event model
- ✅ Guest model
- ✅ Ticket model
- ✅ Message model
- ✅ Auth DTOs (RegisterRequest, LoginRequest, AuthResponse, JWTPayload)

---

## 🚧 In Progress / Next Steps

### Immediate Priorities (Backend API)

1. **[✅] Complete Authentication System**
   - [✅] Implement refresh token storage in Redis
   - [✅] Complete logout endpoint (invalidate tokens in Redis)
   - [✅] Add JWT authentication middleware
   - [✅] Password strength validation improvements
   - [✅] Add bcrypt for password hashing (replace SHA-256)

2. **[ ] Implement Core API Controllers**
   - [ ] **EventController** (CRUD operations)
     - [ ] POST /api/v1/events - Create event
     - [ ] GET /api/v1/events - List events
     - [ ] GET /api/v1/events/:id - Get event details
     - [ ] PUT /api/v1/events/:id - Update event
     - [ ] DELETE /api/v1/events/:id - Delete event
     - [ ] GET /api/v1/events/:id/guests - Get guest list

   - [ ] **VenueController** (CRUD operations)
     - [ ] GET /api/v1/venues/:id - Get venue details
     - [ ] PUT /api/v1/venues/:id - Update venue
     - [ ] GET /api/v1/venues/:id/events - Get venue events

   - [ ] **GuestController** (guest management)
     - [ ] POST /api/v1/guests - Add guest to event
     - [ ] PUT /api/v1/guests/:id/check-in - Check in guest
     - [ ] GET /api/v1/guests/:id - Get guest details

   - [ ] **TicketController** (ticket operations)
     - [ ] GET /api/v1/tickets/:id - Get ticket
     - [ ] POST /api/v1/tickets/validate - Validate ticket QR code
     - [ ] POST /api/v1/tickets/generate - Generate ticket with QR

3. **[ ] Add WebSocket Chat Functionality**
   - [ ] WS /chat/:eventID - Real-time event chat
   - [ ] Message persistence to database
   - [ ] Authentication for WebSocket connections

### Frontend Development

4. **[ ] Build WebUI Frontend Pages**
   - [ ] Landing page
   - [ ] Login/Register pages
   - [ ] Venue dashboard
   - [ ] Event management interface
   - [ ] Guest list view
   - [ ] Ticket scanner interface

5. **[ ] Create Apple Platform Apps**
   - [ ] Add APIClient in Shared package
   - [ ] iOS app screens (SwiftUI)
   - [ ] macOS app screens (SwiftUI)
   - [ ] watchOS complications and screens
   - [ ] visionOS immersive views

### Advanced Features

6. **[ ] QR Code Ticket Validation**
   - [ ] Generate QR codes for tickets
   - [ ] Offline-capable validation logic
   - [ ] Camera integration for scanning

7. **[ ] Testing**
   - [ ] Unit tests for services
   - [ ] Integration tests for API endpoints
   - [ ] End-to-end tests

---

## CI/CD & Deployment

- [ ] **Add GitHub Actions deployment workflow**
  - [ ] Build and test workflow
  - [ ] Trigger on: main branch push after tests pass
  - [ ] SSH into VPS (using GitHub secrets for credentials)
  - [ ] `cd` into project directory
  - [ ] Run `git pull` to get latest code
  - [ ] Execute `make services-up-full` to restart web server container
  - [ ] Verify deployment health check (`curl /health`)

---

## Future Authentication Enhancements

### Magic Email Sign-in
- [ ] Implement magic link email authentication
  - [ ] Generate secure one-time tokens with expiration
  - [ ] Send magic link emails via email service (SendGrid/Mailgun/Resend)
  - [ ] Token validation and single-use enforcement
  - [ ] Auto-login flow after clicking link
  - [ ] Rate limiting for magic link requests

### OAuth Integration
- [ ] **Sign in with Apple**
  - [ ] Apple Developer account configuration
  - [ ] Implement AppleID authentication flow
  - [ ] Token validation and user identity handling
  - [ ] Store Apple user identifiers securely
  - [ ] Handle email privacy (relay@privaterelay.appleid.com)

- [ ] **Sign in with Google**
  - [ ] Google Cloud Console project setup
  - [ ] OAuth 2.0 authorization flow
  - [ ] Token validation and refresh
  - [ ] Store Google user identifiers
  - [ ] Scope management (email, profile)

### Supporting Infrastructure
- [ ] Extend User model for multiple auth providers:
  ```swift
  enum AuthProvider: String {
      case password   // Traditional email/password
      case magicLink  // Passwordless email
      case apple      // Sign in with Apple
      case google     // Sign in with Google
  }
  ```
- [ ] Add fields to User:
  - [ ] `authProvider: AuthProvider`
  - [ ] `externalAuthID: String?` - Provider-specific user ID
  - [ ] Make `passwordHash` optional (not needed for OAuth users)
- [ ] Email service abstraction layer
- [ ] Email templates (HTML + plain text):
  - [ ] Magic link email
  - [ ] Welcome email for new OAuth users
- [ ] Security enhancements:
  - [ ] Rate limiting for magic link and OAuth requests
  - [ ] Token rotation for refresh tokens
  - [ ] OAuth state parameter CSRF protection
  - [ ] Secure token storage in database

---

## Notes

**Development Workflows:**
- Use `make services-up-dev` for containerized development with hot reload (recommended for production parity)
- Use `make dev` for native Swift development with hot reload (faster iteration)
- Use `make services-up-full` to test the production Docker image locally

**Recent Accomplishments:**
- ✅ **Completed comprehensive authentication system** (December 12, 2025):
  - Replaced SHA-256 with bcrypt password hashing (cost factor 12, on NIOThreadPool)
  - Implemented refresh token storage in Redis with 30-day TTL and automatic rotation
  - Added access token blacklisting using JWT ID (jti) for secure logout
  - Created JWT authentication middleware for protected routes
  - Enhanced password strength validation (12 chars, uppercase, lowercase, number, special char)
  - Tested end-to-end authentication flow successfully
- Fixed cross-platform compatibility for DesignSystem.swift (SwiftUI code now properly gated with `#if canImport(SwiftUI)`)
- Implemented cross-platform random token generation (replaced `SecRandomCopyBytes` with `SystemRandomNumberGenerator`)
- Configured server to bind to HOST and PORT environment variables for Docker compatibility
- Successfully tested auth endpoints in containerized environment
