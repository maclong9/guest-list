import Fluent

struct CreateEvents: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("events")
            .id()
            .field("venue_id", .uuid, .required, .references("venues", "id", onDelete: .cascade))
            .field("name", .string, .required)
            .field("description", .string)
            .field("start_time", .datetime, .required)
            .field("end_time", .datetime, .required)
            .field("location", .string)
            .field("capacity", .int)
            .field("status", .string, .required)
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("events").delete()
    }
}
