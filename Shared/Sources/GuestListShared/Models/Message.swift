import Foundation
import FluentGen

/// Represents a chat message in an event
@FluentModel
public struct Message: Codable, Identifiable, Sendable, Hashable {
    public let id: UUID

    public var eventID: UUID

    public var userID: UUID

    public var content: String

    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        eventID: UUID,
        userID: UUID,
        content: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.eventID = eventID
        self.userID = userID
        self.content = content
        self.createdAt = createdAt
    }
}

/// WebSocket message types for real-time chat
public enum ChatMessage: Codable, Sendable {
    case userJoined(UserInfo)
    case userLeft(UserInfo)
    case message(Message)
    case typing(UserInfo)

    public struct UserInfo: Codable, Sendable {
        public let userID: UUID
        public let name: String

        public init(userID: UUID, name: String) {
            self.userID = userID
            self.name = name
        }
    }
}
