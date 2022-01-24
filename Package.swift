// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "SampledPublisher",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "SampledPublisher",
            targets: ["SampledPublisher"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SampledPublisher",
            dependencies: []),
        .testTarget(
            name: "SampledPublisherTests",
            dependencies: ["SampledPublisher"]),
    ]
)
