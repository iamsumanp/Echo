// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Echo",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Echo", targets: ["Echo"])
    ],
    targets: [
        .executableTarget(
            name: "Echo",
            dependencies: [],
            path: "Sources/Echo"
        )
    ]
)
