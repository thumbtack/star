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
    products: [
        .executable(
            name: "star",
            targets: [
                "star",
            ]
        ),
        .library(
            name: "STARLib",
            type: .static,
            targets: [
                "STARLib",
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-package-manager.git", from: "0.3.0"),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "0.50200.0"),
    ],
    targets: [
        .target(
            name: "star",
            dependencies: ["STARLib"]
        ),
        .target(
            name: "STARLib",
            dependencies: ["SwiftSyntax", "SwiftPM"]
        ),
        .testTarget(
            name: "STARLibTests",
            dependencies: ["STARLib"]
        ),
    ]
)
