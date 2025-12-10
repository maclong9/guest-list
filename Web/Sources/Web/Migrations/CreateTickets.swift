import Fluent

struct CreateTickets: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("tickets")
            .id()
            .field("event_id", .uuid, .required, .references("events", "id", onDelete: .cascade))
            .field("guest_id", .uuid, .required, .references("guests", "id", onDelete: .cascade))
            .field("qr_code", .string, .required)
            .field("hmac_signature", .string, .required)
            .field("is_valid", .bool, .required)
            .field("validated_at", .datetime)
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .unique(on: "qr_code")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("tickets").delete()
    }
}
