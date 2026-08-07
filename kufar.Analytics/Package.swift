// swift-tools-version: 5.9
import PackageDescription

// Контракт и реализация в одном пакете, но РАЗНЫМИ продуктами:
// вертикали подключают AnalyticsAPI, корень — AnalyticsImpl.
// Вендорский SDK не попадает в граф ни одной вертикали.

let package = Package(
    name: "KufarAnalytics",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "AnalyticsAPI", targets: ["AnalyticsAPI"]),
        .library(name: "AnalyticsImpl", targets: ["AnalyticsImpl"])
    ],
    dependencies: [
        .package(id: "kufar.Foundation", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "AnalyticsAPI",
            dependencies: [
                .product(name: "SharedKernel", package: "kufar.Foundation")
            ]
        ),
        .target(
            name: "AnalyticsImpl",
            dependencies: [
                "AnalyticsAPI",
                .product(name: "NetworkingInterface", package: "kufar.Foundation")
            ]
        )
    ]
)
