import Foundation
import HummingbirdRedis
import Logging
import NIOCore
@preconcurrency import RediStack

/// Service for managing tokens in Redis
/// - Refresh tokens with TTL
/// - Access token blacklist for logout
/// - User token tracking
actor RedisService: Sendable {
    private let redis: RedisClient
    private let logger: Logger

    init(redis: RedisClient, logger: Logger) {
        self.redis = redis
        self.logger = logger
    }

    // MARK: - Refresh Token Management

    /// Store a refresh token in Redis with expiration
    /// Key: refresh_token:{token}
    /// Value: {userID}
    func storeRefreshToken(token: String, userID: UUID, expiresIn: Int) async throws {
        let key = RedisKey("refresh_token:\(token)")
        let value = userID.uuidString

        _ = try await redis.set(key, to: value).get()
        _ = try await redis.expire(key, after: .seconds(Int64(expiresIn))).get()

        // Also add to user's token set for tracking
        let userKey = RedisKey("user_tokens:\(userID.uuidString)")
        _ = try await redis.sadd(token, to: userKey).get()

        logger.info("Stored refresh token", metadata: ["userID": "\(userID)", "expiresIn": "\(expiresIn)"])
    }

    /// Validate a refresh token and return the associated user ID
    func validateRefreshToken(_ token: String) async throws -> UUID? {
        let key = RedisKey("refresh_token:\(token)")

        guard let value = try await redis.get(key).get().string else {
            logger.warning("Refresh token not found or expired", metadata: ["token": "\(token.prefix(10))..."])
            return nil
        }

        guard let userID = UUID(uuidString: value) else {
            logger.error("Invalid userID in refresh token", metadata: ["value": "\(value)"])
            return nil
        }

        logger.info("Refresh token validated", metadata: ["userID": "\(userID)"])
        return userID
    }

    /// Revoke a refresh token
    func revokeRefreshToken(_ token: String) async throws {
        let key = RedisKey("refresh_token:\(token)")

        // Get userID before deleting to clean up user_tokens set
        if let userIDString = try await redis.get(key).get().string,
            let userID = UUID(uuidString: userIDString)
        {
            let userKey = RedisKey("user_tokens:\(userID.uuidString)")
            _ = try await redis.srem(token, from: userKey).get()
        }

        let deletedCount = try await redis.delete([key]).get()
        logger.info("Revoked refresh token", metadata: ["deleted": "\(deletedCount)"])
    }

    /// Revoke all refresh tokens for a user
    func revokeAllUserTokens(userID: UUID) async throws {
        let userKey = RedisKey("user_tokens:\(userID.uuidString)")

        // Get all tokens for this user
        let tokens = try await redis.smembers(of: userKey).get()

        // Delete each token
        var deletedCount = 0
        for token in tokens {
            if let tokenString = token.string {
                let key = RedisKey(tokenString)
                deletedCount += try await redis.delete([key]).get()
            }
        }

        // Delete the user's token set
        _ = try await redis.delete([userKey]).get()

        logger.info("Revoked all user tokens", metadata: ["userID": "\(userID)", "count": "\(deletedCount)"])
    }

    // MARK: - Access Token Blacklist (for logout)

    /// Blacklist an access token (using JWT ID)
    /// Key: blacklist:{jti}
    /// Value: 1 (presence indicates blacklisted)
    /// TTL: matches token expiration
    func blacklistAccessToken(jti: String, expiresIn: Int) async throws {
        let key = RedisKey("blacklist:\(jti)")

        _ = try await redis.set(key, to: "1").get()
        _ = try await redis.expire(key, after: .seconds(Int64(expiresIn))).get()

        logger.info("Blacklisted access token", metadata: ["jti": "\(jti)", "ttl": "\(expiresIn)"])
    }

    /// Check if an access token is blacklisted
    func isTokenBlacklisted(jti: String) async throws -> Bool {
        let key = RedisKey("blacklist:\(jti)")

        let exists = try await redis.exists([key]).get()
        return exists > 0
    }
}
