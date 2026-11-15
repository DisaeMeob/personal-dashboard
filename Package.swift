// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LifePulseCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "LifePulseCore",
            targets: ["LifePulseCore"]
        )
    ],
    targets: [
        .target(
            name: "LifePulseCore",
            path: "Sources/LifePulseCore"
        ),
        .testTarget(
            name: "LifePulseCoreTests",
            dependencies: ["LifePulseCore"],
            path: "Tests/LifePulseCoreTests"
        )
    ]
)
