// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "GuestListShared",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "GuestListShared", targets: ["GuestListShared"]),
    ],
    dependencies: [
        .package(path: "../../../Tooling/FluentGen"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
    ],
    targets: [
        .target(
            name: "GuestListShared",
            dependencies: [
                .product(name: "FluentGen", package: "FluentGen"),
                .product(name: "Fluent", package: "fluent"),
            ],
            path: "Sources/GuestListShared"
        ),
        .testTarget(
            name: "GuestListSharedTests",
            dependencies: ["GuestListShared"],
            path: "Tests/GuestListSharedTests"
        ),
    ]
)
