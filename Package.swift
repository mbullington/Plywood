// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Plywood",
    products: [
        .library(name: "Cwlroots", targets: ["Cwlroots"]),
        .library(name: "SwiftWLR", targets: ["SwiftWLR"]),
        .executable(name: "Plywood", targets: ["Plywood"]),
    ],
    dependencies: [
        .package(url: "https://github.com/bloomos/swift-wayland.git", .branch("master")),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/bloomos/TweenKit.git", .branch("master")),
        .package(url: "https://github.com/bloomos/SkiaKit.git", .branch("bloom-hotfixes"))
    ],
    targets: [
        .systemLibrary(
            name: "Cwlroots",
            pkgConfig: "wlroots"
        ),
        .target(
            name: "SwiftWLR",
            dependencies: ["Cwayland", "Cwlroots", "SwiftWayland", "Logging"],
            cSettings: [
                .define("WLR_USE_UNSTABLE"),
                .headerSearchPath("External"),
            ]
        ),
        .target(
            name: "Cplywood",
            cSettings: [
            .headerSearchPath("include"),
            ]
        ),
        .target(
            name: "Plywood",
            dependencies: [
                "Cwlroots",
                "Cplywood",
                "SwiftWayland",
                "SwiftWLR",
                "Logging",
                "TweenKit",
                "SkiaKit"
            ],
            cSettings: [
                .define("WLR_USE_UNSTABLE"),
            ],
            // Needed since we have code implementation in the .h files (Cplywood).
            // This /works/, but the IR doesn't detect it.
            swiftSettings: [
                .unsafeFlags(["-Xfrontend", "-validate-tbd-against-ir=none"]),
            ]
        ),
    ]
)
