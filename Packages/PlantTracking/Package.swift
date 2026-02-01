// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "PlantTracking",
    platforms: [.iOS(.v26)],
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
