// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "PathDeck",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "PathDeck", targets: ["PathDeck"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "PathDeck",
            dependencies: [],
            path: "sources/pathdeck"
        ),
        .testTarget(
            name: "PathDeckTests",
            dependencies: ["PathDeck"],
            path: "tests/pathdecktests"
        )
    ]
)
