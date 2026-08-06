// swift-tools-version: 5.9
import PackageDescription

// Снапшот-тесты компонентов не поднимают приложение.

let package = Package(
    name: "KufarDesignComponents",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "DesignComponents", targets: ["DesignComponents"])
    ],
    dependencies: [
        .package(id: "kufar.DesignTokens", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "DesignComponents",
            dependencies: [
                .product(name: "DesignTokens", package: "kufar.DesignTokens")
            ]
        )
    ]
)
