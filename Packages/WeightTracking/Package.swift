// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "WeightTracking",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "WeightTracking", targets: ["WeightTracking"])
    ],
    dependencies: [
        .package(path: "../CaloriesFoundation")
    ],
    targets: [
        .target(
            name: "WeightTracking",
            dependencies: ["CaloriesFoundation"],
            path: "Sources/WeightTracking",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "WeightTrackingTests",
            dependencies: ["WeightTracking", "CaloriesFoundation"],
            path: "Tests/WeightTrackingTests"
        ),
    ]
)
