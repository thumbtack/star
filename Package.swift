// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftTypeAdoptionReporter",
    dependencies: [
        .package(url: "https://github.com/apple/swift-package-manager.git", from: "0.3.0"),
        .package(url: "https://github.com/apple/swift-syntax.git", .branch("0.50100.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "swift-type-adoption-reporter",
            dependencies: ["SwiftTypeAdoptionReporter"]),
        .target(
            name: "SwiftTypeAdoptionReporter",
            dependencies: ["SwiftSyntax", "SwiftPM"]),
        .testTarget(
            name: "SwiftTypeAdoptionReporterTests",
            dependencies: ["SwiftTypeAdoptionReporter"]),
    ]
)
