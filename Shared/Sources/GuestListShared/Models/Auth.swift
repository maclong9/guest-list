import Foundation

// MARK: - Authentication Request DTOs

/// Request to register a new venue and owner user
public struct RegisterRequest: Codable, Sendable {
    public let venueName: String
    public let venueAddress: String
    public let email: String
    public let password: String
    public let firstName: String
    public let lastName: String

    public init(
        venueName: String,
        venueAddress: String,
        email: String,
        password: String,
        firstName: String,
        lastName: String
    ) {
        self.venueName = venueName
        self.venueAddress = venueAddress
        self.email = email
        self.password = password
        self.firstName = firstName
        self.lastName = lastName
    }
}

/// Request to login with email and password
public struct LoginRequest: Codable, Sendable {
    public let email: String
    public let password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

/// Request to refresh an access token
public struct RefreshTokenRequest: Codable, Sendable {
    public let refreshToken: String

    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}

/// Request to logout (optional refresh token to revoke)
public struct LogoutRequest: Codable, Sendable {
    public let refreshToken: String?

    public init(refreshToken: String? = nil) {
        self.refreshToken = refreshToken
    }
}

// MARK: - Authentication Response DTOs

/// Response containing JWT tokens
public struct AuthResponse: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int
    public let user: UserPublic

    public init(accessToken: String, refreshToken: String, expiresIn: Int, user: UserPublic) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.user = user
    }
}

/// Public user information (without sensitive data)
public struct UserPublic: Codable, Sendable, Identifiable {
    public let id: UUID
    public let venueID: UUID
    public let email: String
    public let firstName: String
    public let lastName: String
    public let role: UserRole
    public let isActive: Bool
    public let createdAt: Date

    public init(
        id: UUID,
        venueID: UUID,
        email: String,
        firstName: String,
        lastName: String,
        role: UserRole,
        isActive: Bool,
        createdAt: Date
    ) {
        self.id = id
        self.venueID = venueID
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.role = role
        self.isActive = isActive
        self.createdAt = createdAt
    }

    public var fullName: String {
        "\(firstName) \(lastName)"
    }

    /// Convert from User model to UserPublic (removing sensitive data)
    public init(from user: User) {
        self.id = user.id
        self.venueID = user.venueID
        self.email = user.email
        self.firstName = user.firstName
        self.lastName = user.lastName
        self.role = user.role
        self.isActive = user.isActive
        self.createdAt = user.createdAt
    }
}

/// JWT token payload
public struct JWTPayload: Codable, Sendable {
    public let jti: String    // JWT ID (for revocation/blacklisting)
    public let sub: UUID      // Subject (user ID)
    public let exp: Int       // Expiration time
    public let iat: Int       // Issued at
    public let role: UserRole
    public let venueID: UUID

    public init(jti: String, sub: UUID, exp: Int, iat: Int, role: UserRole, venueID: UUID) {
        self.jti = jti
        self.sub = sub
        self.exp = exp
        self.iat = iat
        self.role = role
        self.venueID = venueID
    }
}
