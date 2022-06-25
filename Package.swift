// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "tuist-module",
    platforms: [.macOS(.v11)],
    products: [
        .library(
            name: "TuistModule",
            targets: ["TuistModule"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/tuist/ProjectDescription", .exact("3.2.0")),
    ],
    targets: [
        .target(
            name: "TuistModule",
            dependencies: [
                "ProjectDescription"
            ],
            path: "ProjectDescriptionHelpers"
        ),
        .testTarget(
            name: "TuistModuleTests",
            dependencies: [
                "TuistModule",
            ]
        ),
    ]
)
