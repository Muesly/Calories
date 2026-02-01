// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Charting",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "Charting", targets: ["Charting"])
    ],
    dependencies: [
        .package(path: "../CaloriesFoundation")
    ],
    targets: [
        .target(
            name: "Charting",
            dependencies: ["CaloriesFoundation"],
            path: "Sources/Charting",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ChartingTests",
            dependencies: ["Charting", "CaloriesFoundation"],
            path: "Tests/ChartingTests"
        ),
    ]
)
