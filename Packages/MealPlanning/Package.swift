// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MealPlanning",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "MealPlanning", targets: ["MealPlanning"])
    ],
    dependencies: [
        .package(path: "../CaloriesFoundation")
    ],
    targets: [
        .target(
            name: "MealPlanning",
            dependencies: ["CaloriesFoundation"],
            path: "Sources/MealPlanning",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "MealPlanningTests",
            dependencies: ["MealPlanning", "CaloriesFoundation"],
            path: "Tests/MealPlanningTests"
        ),
    ]
)
