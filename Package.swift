// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SwiftImageCache",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "SwiftImageCache",
            targets: ["SwiftImageCache"]
        )
    ],
    targets: [
        .target(
            name: "SwiftImageCache",
            path: "Sources/SwiftImageCache"
        ),
        .testTarget(
            name: "SwiftImageCacheTests",
            dependencies: ["SwiftImageCache"],
            path: "Tests/SwiftImageCacheTests"
        )
    ]
)
