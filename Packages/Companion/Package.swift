// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Companion",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "Companion", targets: ["Companion"])
    ],
    dependencies: [
        .package(path: "../CaloriesFoundation")
    ],
    targets: [
        .target(
            name: "Companion",
            dependencies: ["CaloriesFoundation"],
            path: "Sources/Companion",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "CompanionTests",
            dependencies: ["Companion", "CaloriesFoundation"],
            path: "Tests/CompanionTests"
        ),
    ]
)
