// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "FoodTracking",
    platforms: [.iOS(.v26), .watchOS(.v10)],
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
