import Fluent

struct CreateVenues: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("venues")
            .id()
            .field("name", .string, .required)
            .field("email", .string, .required)
            .field("phone_number", .string)
            .field("address", .string)
            .field("city", .string)
            .field("state", .string)
            .field("zip_code", .string)
            .field("country", .string, .required)
            .field("tier", .string, .required)
            .field("is_active", .bool, .required)
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .unique(on: "email")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("venues").delete()
    }
}
