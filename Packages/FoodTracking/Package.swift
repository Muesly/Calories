// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FoodTracking",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "FoodTracking", targets: ["FoodTracking"])
    ],
    dependencies: [
        .package(path: "../CaloriesFoundation")
    ],
    targets: [
        .target(
            name: "FoodTracking",
            dependencies: ["CaloriesFoundation"],
            path: "Sources/FoodTracking",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "FoodTrackingTests",
            dependencies: ["FoodTracking", "CaloriesFoundation"],
            path: "Tests/FoodTrackingTests"
        ),
    ]
)
