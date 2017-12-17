// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JSONModelGenerator",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .executable(
            name: "JSONModelGenerator",
            targets: ["JSONModelGenerator"]),
    ],
    dependencies:  [
        .package(url: "https://github.com/apple/swift-package-manager.git", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "JSONModelGenerator",
            dependencies: ["JSONModelGeneratorCore", "Utility"]),
        .target(
            name: "JSONModelGeneratorCore",
            dependencies: ["Utility"]),
        .testTarget(
            name: "JSONModelGeneratorTests",
            dependencies: ["JSONModelGenerator"]),
    ]
)

