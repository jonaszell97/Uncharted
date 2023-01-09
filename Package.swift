// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FlipCharts",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "FlipCharts",
            targets: ["FlipCharts"]),
    ],
    dependencies: [
        .package(url: "/Users/jonaszell/Toolbox", branch: "dev"),
        .package(url: "/Users/jonaszell/Panorama", branch: "dev"),
    ],
    targets: [
        .target(
            name: "FlipCharts",
            dependencies: ["Toolbox", "Panorama"]),
        .testTarget(
            name: "FlipChartsTests",
            dependencies: ["FlipCharts", "Toolbox", "Panorama"]),
    ]
)
