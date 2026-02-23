// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OmniPostD",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "OmniPostD", targets: ["OmniPostD"]),
    ],
    targets: [
        .executableTarget(
            name: "OmniPostD"
        ),
        .testTarget(
            name: "OmniPostDTests",
            dependencies: ["OmniPostD"]
        ),
    ]
)
