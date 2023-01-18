// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Uncharted",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "Uncharted",
            targets: ["Uncharted"]),
    ],
    dependencies: [
        .package(url: "/Users/jonaszell/Toolbox", branch: "dev"),
        .package(url: "/Users/jonaszell/Panorama", branch: "dev"),
    ],
    targets: [
        .target(
            name: "Uncharted",
            dependencies: ["Toolbox", "Panorama"]),
        .testTarget(
            name: "UnchartedTests",
            dependencies: ["Uncharted", "Toolbox", "Panorama"]),
    ]
)
