import Fluent

struct CreateGuests: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("guests")
            .id()
            .field("event_id", .uuid, .required, .references("events", "id", onDelete: .cascade))
            .field("first_name", .string, .required)
            .field("last_name", .string, .required)
            .field("email", .string)
            .field("phone_number", .string)
            .field("ticket_type", .string, .required)
            .field("is_checked_in", .bool, .required)
            .field("checked_in_at", .datetime)
            .field("notes", .string)
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("guests").delete()
    }
}
