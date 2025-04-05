// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PoseDetection",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "PoseDetection",
            targets: ["PoseDetection"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PoseDetection",
            dependencies: [],
            path: "PoseDetection",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "PoseDetectionTests",
            dependencies: ["PoseDetection"],
            path: "PoseDetectionTests"
        ),
    ]
) 