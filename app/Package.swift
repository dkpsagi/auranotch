// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AuraNotch",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "AuraNotch", targets: ["AuraNotch"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "AuraNotch",
            dependencies: [],
            path: "Sources/AuraNotch"
        )
    ]
)
