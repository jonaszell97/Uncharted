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
        .package(url: "https://github.com/jonaszell97/Toolbox.git", from: "0.2.0"),
        .package(url: "https://github.com/jonaszell97/Panorama.git", from: "0.2.0"),
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
