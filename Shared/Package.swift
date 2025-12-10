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
    targets: [
        .target(
            name: "GuestListShared",
            path: "Sources/GuestListShared"
        ),
        .testTarget(
            name: "GuestListSharedTests",
            dependencies: ["GuestListShared"],
            path: "Tests/GuestListSharedTests"
        ),
    ]
)
