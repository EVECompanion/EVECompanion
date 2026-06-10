// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "EVECompanionTools",
    products: [
        .executable(name: "SDEConverter", targets: ["SDEConverter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", exact: "0.15.4"),
        .package(url: "https://github.com/jpsim/Yams.git", exact: "6.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", exact: "1.6.2"),
    ],
    targets: [
        .executableTarget(
            name: "SDEConverter",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift"),
                .product(name: "Yams", package: "Yams"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "SDEConverter",
            exclude: [
                "Dockerfile",
            ],
            resources: [
                .copy("effect_patches.json"),
            ]
        ),
    ]
)
