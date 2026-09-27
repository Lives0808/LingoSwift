// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LingoSwift",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "LingoSwift", targets: ["LingoSwift"])
    ],
    targets: [
        .executableTarget(
            name: "LingoSwift",
            path: "Sources/LingoSwift",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
