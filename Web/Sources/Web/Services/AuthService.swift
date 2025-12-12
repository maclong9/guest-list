import Crypto
import Foundation
import GuestListShared
import HummingbirdAuth
import HummingbirdBcrypt
import NIOCore
import NIOPosix

/// Service for authentication operations (password hashing, JWT generation)
actor AuthService: Sendable {
    private let jwtSecret: String
    private let jwtExpirationHours: Int
    private let refreshTokenExpirationDays: Int

    init(jwtSecret: String, jwtExpirationHours: Int = 24, refreshTokenExpirationDays: Int = 30) {
        self.jwtSecret = jwtSecret
        self.jwtExpirationHours = jwtExpirationHours
        self.refreshTokenExpirationDays = refreshTokenExpirationDays
    }

    // MARK: - Password Hashing

    /// Hash a password using bcrypt with cost factor 12
    /// Bcrypt provides built-in salting and is designed specifically for password hashing
    func hashPassword(_ password: String) async throws -> String {
        guard !password.isEmpty else {
            throw AuthError.invalidPassword
        }

        // Use bcrypt with cost factor 12 (good balance of security and performance)
        // Run on thread pool to avoid blocking the event loop
        return try await NIOThreadPool.singleton.runIfActive {
            Bcrypt.hash(password, cost: 12)
        }
    }

    /// Verify a password against a bcrypt hash
    func verifyPassword(_ password: String, hash: String) async throws -> Bool {
        guard !password.isEmpty, !hash.isEmpty else {
            throw AuthError.invalidPassword
        }

        // Run verification on thread pool to avoid blocking the event loop
        return try await NIOThreadPool.singleton.runIfActive {
            Bcrypt.verify(password, hash: hash)
        }
    }

    // MARK: - JWT Token Generation

    /// Generate a JWT access token for a user
    func generateAccessToken(user: User) throws -> String {
        let now = Date()
        let expiration = now.addingTimeInterval(TimeInterval(jwtExpirationHours * 3600))

        // Generate unique JWT ID for revocation/blacklisting
        let jti = UUID().uuidString

        let payload = JWTPayload(
            jti: jti,
            sub: user.id,
            exp: Int(expiration.timeIntervalSince1970),
            iat: Int(now.timeIntervalSince1970),
            role: user.role,
            venueID: user.venueID
        )

        return try encodeJWT(payload: payload)
    }

    /// Generate a refresh token (longer-lived, simpler token)
    func generateRefreshToken() -> String {
        // Generate a random 32-byte token using cross-platform SystemRandomNumberGenerator
        var bytes = [UInt8](repeating: 0, count: 32)
        var rng = SystemRandomNumberGenerator()
        for i in 0..<bytes.count {
            bytes[i] = UInt8.random(in: 0...255, using: &rng)
        }
        return Data(bytes).base64EncodedString()
    }

    /// Verify and decode a JWT token
    func verifyAccessToken(_ token: String) throws -> JWTPayload {
        try decodeJWT(token: token)
    }

    // MARK: - Private JWT Helpers

    private func encodeJWT(payload: JWTPayload) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970

        let payloadData = try encoder.encode(payload)
        let payloadBase64 = payloadData.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        // Create header
        let header = "{\"alg\":\"HS256\",\"typ\":\"JWT\"}"
        guard let headerData = header.data(using: .utf8) else {
            throw AuthError.tokenGenerationFailed
        }
        let headerBase64 = headerData.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        // Create signature
        let signingInput = "\(headerBase64).\(payloadBase64)"
        guard let signingData = signingInput.data(using: .utf8), let secretData = jwtSecret.data(using: .utf8) else {
            throw AuthError.tokenGenerationFailed
        }

        let signature = HMAC<SHA256>.authenticationCode(for: signingData, using: SymmetricKey(data: secretData))
        let signatureBase64 = Data(signature).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        return "\(headerBase64).\(payloadBase64).\(signatureBase64)"
    }

    private func decodeJWT(token: String) throws -> JWTPayload {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else {
            throw AuthError.invalidToken
        }

        // Verify signature
        let headerAndPayload = "\(parts[0]).\(parts[1])"
        guard let signingData = headerAndPayload.data(using: .utf8), let secretData = jwtSecret.data(using: .utf8) else {
            throw AuthError.invalidToken
        }

        let expectedSignature = HMAC<SHA256>.authenticationCode(for: signingData, using: SymmetricKey(data: secretData))
        let expectedSignatureBase64 = Data(expectedSignature).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        guard expectedSignatureBase64 == parts[2] else {
            throw AuthError.invalidToken
        }

        // Decode payload
        var payloadBase64 = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Add padding if needed
        let paddingLength = (4 - payloadBase64.count % 4) % 4
        payloadBase64 += String(repeating: "=", count: paddingLength)

        guard let payloadData = Data(base64Encoded: payloadBase64) else {
            throw AuthError.invalidToken
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let payload = try decoder.decode(JWTPayload.self, from: payloadData)

        // Check expiration
        let now = Int(Date().timeIntervalSince1970)
        guard payload.exp > now else {
            throw AuthError.tokenExpired
        }

        return payload
    }
}

// MARK: - Auth Errors

enum AuthError: Error, Sendable {
    case invalidPassword
    case invalidCredentials
    case tokenGenerationFailed
    case invalidToken
    case tokenExpired
    case userNotFound
    case emailAlreadyExists
    case venueNotFound
}
