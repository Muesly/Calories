// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ExerciseTracking",
    platforms: [.iOS(.v17), .watchOS(.v10)],
    products: [
        .library(name: "ExerciseTracking", targets: ["ExerciseTracking"])
    ],
    dependencies: [
        .package(path: "../CaloriesFoundation")
    ],
    targets: [
        .target(
            name: "ExerciseTracking",
            dependencies: ["CaloriesFoundation"],
            path: "Sources/ExerciseTracking",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ExerciseTrackingTests",
            dependencies: ["ExerciseTracking", "CaloriesFoundation"],
            path: "Tests/ExerciseTrackingTests"
        ),
    ]
)
