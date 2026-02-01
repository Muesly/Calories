// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CaloriesFoundation",
    platforms: [.iOS(.v17), .watchOS(.v10)],
    products: [
        .library(name: "CaloriesFoundation", targets: ["CaloriesFoundation"])
    ],
    targets: [
        .target(
            name: "CaloriesFoundation",
            dependencies: [],
            path: "Sources/CaloriesFoundation",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "CaloriesFoundationTests",
            dependencies: ["CaloriesFoundation"],
            path: "Tests/CaloriesFoundationTests"
        ),
    ]
)
