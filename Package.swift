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
        .package(url: "https://github.com/jonaszell97/Toolbox.git", from: "0.1.0"),
        .package(url: "https://github.com/jonaszell97/Panorama.git", from: "0.1.0"),
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
