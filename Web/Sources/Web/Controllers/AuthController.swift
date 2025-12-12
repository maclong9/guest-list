import Fluent
import Foundation
import GuestListShared
import Hummingbird
import HummingbirdFluent
import Logging

/// Controller for authentication endpoints
struct AuthController: Sendable {
    let authService: AuthService
    let redisService: RedisService
    let fluent: Fluent
    let logger: Logger

    init(authService: AuthService, redisService: RedisService, fluent: Fluent, logger: Logger) {
        self.authService = authService
        self.redisService = redisService
        self.fluent = fluent
        self.logger = logger
    }

    // MARK: - Routes

    func addRoutes(to group: RouterGroup<some RequestContext>) {
        group.post("register", use: register)
        group.post("login", use: login)
        group.post("refresh", use: refreshToken)
        group.post("logout", use: logout)
    }

    // MARK: - Handlers

    /// POST /api/v1/auth/register
    /// Register a new venue with an owner user
    @Sendable
    private func register(_ request: Request, context: some RequestContext) async throws -> Response {
        logger.info("Register endpoint called")

        let registerRequest = try await request.decode(as: RegisterRequest.self, context: context)
        logger.info("Request decoded successfully", metadata: ["email": "\(registerRequest.email)"])

        // Validate email format
        guard registerRequest.email.contains("@") else {
            logger.warning("Invalid email format", metadata: ["email": "\(registerRequest.email)"])
            throw HTTPError(.badRequest, message: "Invalid email format")
        }

        // Validate password strength
        try validatePasswordStrength(registerRequest.password)

        // Check if email already exists
        let existingUser = try await UserModel.query(on: fluent.db()).filter(\.$email == registerRequest.email).first()
        if existingUser != nil {
            throw HTTPError(.conflict, message: "Email already registered")
        }

        logger.info("Hashing password...")
        // Hash password
        let passwordHash = try await authService.hashPassword(registerRequest.password)
        logger.info("Password hashed successfully")

        logger.info("Creating venue...")
        // Create venue DTO and model
        let venueDTO = Venue(
            id: UUID(),
            name: registerRequest.venueName,
            email: registerRequest.email,
            address: registerRequest.venueAddress
        )
        let venueModel = VenueModel(from: venueDTO)
        logger.info("Venue model created, saving to database...")

        do {
            try await venueModel.save(on: fluent.db())
            logger.info("Created venue", metadata: ["venue_id": "\(venueDTO.id)", "name": "\(venueDTO.name)"])
        } catch {
            logger.error("Failed to save venue", metadata: [
                "error": "\(String(reflecting: error))",
                "type": "\(type(of: error))",
                "venue_name": "\(registerRequest.venueName)"
            ])
            throw HTTPError(.internalServerError, message: "Failed to create venue: \(String(reflecting: error))")
        }

        // Create owner user DTO and model
        let userDTO = User(
            id: UUID(),
            venueID: venueDTO.id,
            email: registerRequest.email,
            passwordHash: passwordHash,
            firstName: registerRequest.firstName,
            lastName: registerRequest.lastName,
            role: .owner,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
        let userModel = UserModel(from: userDTO)
        logger.info("Saving user to database...")
        try await userModel.save(on: fluent.db())
        logger.info("Created user", metadata: ["user_id": "\(userDTO.id)", "email": "\(userDTO.email)", "role": "owner"])

        // Generate tokens
        let accessToken = try await authService.generateAccessToken(user: userDTO)
        let refreshToken = await authService.generateRefreshToken()

        // Store refresh token in Redis (30 days TTL)
        let refreshTokenTTL = 30 * 24 * 3600  // 30 days in seconds
        try await redisService.storeRefreshToken(token: refreshToken, userID: userDTO.id, expiresIn: refreshTokenTTL)

        let response = AuthResponse(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: 24 * 3600,
            user: UserPublic(from: userDTO)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let responseData = try encoder.encode(response)

        return Response(
            status: .created,
            headers: [.contentType: "application/json"],
            body: .init(byteBuffer: .init(data: responseData))
        )
    }

    /// POST /api/v1/auth/login
    /// Login with email and password
    @Sendable
    private func login(_ request: Request, context: some RequestContext) async throws -> Response {
        let loginRequest = try await request.decode(as: LoginRequest.self, context: context)

        // Find user by email
        guard let userModel = try await UserModel.query(on: fluent.db()).filter(\.$email == loginRequest.email).first() else {
            logger.warning("Login attempt with non-existent email", metadata: ["email": "\(loginRequest.email)"])
            throw HTTPError(.unauthorized, message: "Invalid credentials")
        }

        // Convert to DTO for easier access
        let userDTO = userModel.toDTO()

        // Verify password
        let isValidPassword = try await authService.verifyPassword(loginRequest.password, hash: userDTO.passwordHash)
        guard isValidPassword else {
            logger.warning("Login attempt with invalid password", metadata: ["user_id": "\(userDTO.id)", "email": "\(userDTO.email)"])
            throw HTTPError(.unauthorized, message: "Invalid credentials")
        }

        // Check if user is active
        guard userDTO.isActive else {
            logger.warning("Login attempt with inactive user", metadata: ["user_id": "\(userDTO.id)", "email": "\(userDTO.email)"])
            throw HTTPError(.forbidden, message: "Account is disabled")
        }

        // Generate tokens
        let accessToken = try await authService.generateAccessToken(user: userDTO)
        let refreshToken = await authService.generateRefreshToken()

        // Store refresh token in Redis (30 days TTL)
        let refreshTokenTTL = 30 * 24 * 3600  // 30 days in seconds
        try await redisService.storeRefreshToken(token: refreshToken, userID: userDTO.id, expiresIn: refreshTokenTTL)

        logger.info("User logged in successfully", metadata: ["user_id": "\(userDTO.id)", "email": "\(userDTO.email)"])

        let response = AuthResponse(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: 24 * 3600,
            user: UserPublic(from: userDTO)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let responseData = try encoder.encode(response)

        return Response(
            status: .ok,
            headers: [.contentType: "application/json"],
            body: .init(byteBuffer: .init(data: responseData))
        )
    }

    /// POST /api/v1/auth/refresh
    /// Refresh access token using refresh token (with rotation)
    @Sendable
    private func refreshToken(_ request: Request, context: some RequestContext) async throws -> Response {
        let refreshRequest = try await request.decode(as: RefreshTokenRequest.self, context: context)

        logger.info("Refresh token endpoint called")

        // Validate refresh token in Redis
        guard let userID = try await redisService.validateRefreshToken(refreshRequest.refreshToken) else {
            logger.warning("Invalid or expired refresh token")
            throw HTTPError(.unauthorized, message: "Invalid or expired refresh token")
        }

        // Load user from database
        guard let userModel = try await UserModel.query(on: fluent.db()).filter(\.$id == userID).first() else {
            logger.error("User not found for valid refresh token", metadata: ["userID": "\(userID)"])
            throw HTTPError(.unauthorized, message: "User not found")
        }

        let userDTO = userModel.toDTO()

        // Check if user is active
        guard userDTO.isActive else {
            logger.warning("Refresh attempt with inactive user", metadata: ["user_id": "\(userDTO.id)"])
            throw HTTPError(.forbidden, message: "Account is disabled")
        }

        // Generate new tokens (rotate refresh token)
        let newAccessToken = try await authService.generateAccessToken(user: userDTO)
        let newRefreshToken = await authService.generateRefreshToken()

        // Store new refresh token and revoke old one
        let refreshTokenTTL = 30 * 24 * 3600  // 30 days in seconds
        try await redisService.storeRefreshToken(token: newRefreshToken, userID: userDTO.id, expiresIn: refreshTokenTTL)
        try await redisService.revokeRefreshToken(refreshRequest.refreshToken)

        logger.info("Tokens refreshed successfully", metadata: ["user_id": "\(userDTO.id)"])

        let response = AuthResponse(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
            expiresIn: 24 * 3600,
            user: UserPublic(from: userDTO)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let responseData = try encoder.encode(response)

        return Response(
            status: .ok,
            headers: [.contentType: "application/json"],
            body: .init(byteBuffer: .init(data: responseData))
        )
    }

    /// POST /api/v1/auth/logout
    /// Logout (invalidate current access token and optional refresh token)
    @Sendable
    private func logout(_ request: Request, context: some RequestContext) async throws -> Response {
        logger.info("Logout endpoint called")

        // Extract and validate JWT from Authorization header
        guard let authHeader = request.headers[.authorization],
              authHeader.hasPrefix("Bearer ")
        else {
            throw HTTPError(.unauthorized, message: "Missing or invalid Authorization header")
        }

        let token = String(authHeader.dropFirst("Bearer ".count))

        // Decode JWT to get jti and exp
        let payload = try await authService.verifyAccessToken(token)

        // Calculate remaining TTL for access token
        let now = Int(Date().timeIntervalSince1970)
        let remainingTTL = max(payload.exp - now, 0)

        // Blacklist the access token
        try await redisService.blacklistAccessToken(jti: payload.jti, expiresIn: remainingTTL)

        // Optionally revoke refresh token if provided
        let logoutRequest = try? await request.decode(as: LogoutRequest.self, context: context)
        if let refreshToken = logoutRequest?.refreshToken {
            try await redisService.revokeRefreshToken(refreshToken)
            logger.info("Revoked refresh token", metadata: ["user_id": "\(payload.sub)"])
        }

        logger.info("User logged out successfully", metadata: ["user_id": "\(payload.sub)", "jti": "\(payload.jti)"])

        return Response(
            status: .ok,
            headers: [.contentType: "application/json"],
            body: .init(byteBuffer: .init(string: "{\"message\":\"Logged out successfully\"}"))
        )
    }

    // MARK: - Private Helpers

    /// Validate password strength with hardcoded requirements
    /// - Minimum 12 characters
    /// - At least one uppercase letter
    /// - At least one lowercase letter
    /// - At least one number
    /// - At least one special character
    private func validatePasswordStrength(_ password: String) throws {
        var errors: [String] = []

        // Check minimum length
        if password.count < 12 {
            errors.append("at least 12 characters")
        }

        // Check for uppercase letter
        if !password.contains(where: { $0.isUppercase }) {
            errors.append("at least one uppercase letter")
        }

        // Check for lowercase letter
        if !password.contains(where: { $0.isLowercase }) {
            errors.append("at least one lowercase letter")
        }

        // Check for number
        if !password.contains(where: { $0.isNumber }) {
            errors.append("at least one number")
        }

        // Check for special character
        let specialCharacters = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")
        if !password.unicodeScalars.contains(where: { specialCharacters.contains($0) }) {
            errors.append("at least one special character (!@#$%^&*()_+-=[]{}|;:,.<>?)")
        }

        if !errors.isEmpty {
            let errorMessage = "Password must contain " + errors.joined(separator: ", ")
            throw HTTPError(.badRequest, message: errorMessage)
        }
    }
}
