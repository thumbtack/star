// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

// Copyright 2020 Thumbtack, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import PackageDescription

let package = Package(
    name: "SwiftTypeAdoptionReporter",
    dependencies: [
        .package(url: "https://github.com/apple/swift-package-manager.git", from: "0.3.0"),
        .package(url: "https://github.com/apple/swift-syntax.git", .branch("0.50100.0")),
        .package(url: "https://github.com/jpsim/SourceKitten.git", from: "0.29.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "swift-type-adoption-reporter",
            dependencies: ["SwiftTypeAdoptionReporter"]),
        .target(
            name: "SwiftTypeAdoptionReporter",
            dependencies: ["SwiftSyntax", "SwiftPM", "SourceKittenFramework"]),
        .testTarget(
            name: "SwiftTypeAdoptionReporterTests",
            dependencies: ["SwiftTypeAdoptionReporter"]),
    ]
)
