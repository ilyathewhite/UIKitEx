// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UIKitEx",
    platforms: [
        .macOS(.v11), .iOS(.v14), .tvOS(.v14)
    ],
    products: [
        .library(
            name: "UIKitEx",
            targets: ["UIKitEx"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ilyathewhite/FoundationEx.git", .branch("main")),
        .package(url: "https://github.com/ilyathewhite/CombineEx.git", .branch("main")),
        .package(url: "https://github.com/ilyathewhite/ReducerArchitecture.git", .branch("master")),
        .package(url: "https://github.com/ilyathewhite/Functional.git", .branch("main"))
    ],
    targets: [
        .target(
            name: "UIKitEx",
            dependencies: ["FoundationEx", "CombineEx", "ReducerArchitecture", "Functional"],
            swiftSettings: [.unsafeFlags([
                "-Xfrontend",
                "-warn-long-function-bodies=100",
                "-Xfrontend",
                "-warn-long-expression-type-checking=100"
            ])]
        ),
        .testTarget(
            name: "UIKitExTests",
            dependencies: ["UIKitEx"]
        )
    ]
)
