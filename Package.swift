// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "KillAll",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "KillAll",
            path: "Sources/KillAll"
        )
    ]
)
