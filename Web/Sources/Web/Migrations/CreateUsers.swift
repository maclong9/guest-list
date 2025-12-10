import Fluent

struct CreateUsers: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .id()
            .field("venue_id", .uuid, .required, .references("venues", "id", onDelete: .cascade))
            .field("email", .string, .required)
            .field("password_hash", .string, .required)
            .field("first_name", .string, .required)
            .field("last_name", .string, .required)
            .field("role", .string, .required)
            .field("is_active", .bool, .required)
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .unique(on: "email")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
