// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Diptychon",
    platforms: [
        .macOS(.v14) // macOS 14 Sonoma minimum (PRD).
    ],
    targets: [
        // Tools version 5.9 → Swift 5 language mode by default, keeping
        // strict-concurrency friction low for the tracer bullet.
        .executableTarget(
            name: "Diptychon",
            path: "Sources/Diptychon"
        )
    ]
)
