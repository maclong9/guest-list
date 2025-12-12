// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Web",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "Web", targets: ["Web"]),
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.21.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird-redis.git", from: "2.0.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird-websocket.git", from: "2.0.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird-auth.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        .package(url: "https://github.com/apple/swift-metrics.git", from: "2.4.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
        .package(url: "https://github.com/maclong9/web-ui", branch: "main"),
        .package(path: "../Shared"),
    ],
    targets: [
        .executableTarget(
            name: "Web",
            dependencies: [
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "PostgresNIO", package: "postgres-nio"),
                .product(name: "HummingbirdRedis", package: "hummingbird-redis"),
                .product(name: "HummingbirdWebSocket", package: "hummingbird-websocket"),
                .product(name: "HummingbirdAuth", package: "hummingbird-auth"),
                .product(name: "HummingbirdBcrypt", package: "hummingbird-auth"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Metrics", package: "swift-metrics"),
                .product(name: "WebUI", package: "web-ui"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "GuestListShared", package: "Shared"),
            ],
            path: "Sources/Web"
        ),
        .testTarget(
            name: "WebTests",
            dependencies: ["Web"],
            path: "Tests/WebTests"
        ),
    ]
)
