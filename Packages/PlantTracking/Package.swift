// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PlantTracking",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "PlantTracking", targets: ["PlantTracking"])
    ],
    dependencies: [
        .package(path: "../CaloriesFoundation")
    ],
    targets: [
        .target(
            name: "PlantTracking",
            dependencies: ["CaloriesFoundation"],
            path: "Sources/PlantTracking",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "PlantTrackingTests",
            dependencies: ["PlantTracking", "CaloriesFoundation"],
            path: "Tests/PlantTrackingTests"
        ),
    ]
)
