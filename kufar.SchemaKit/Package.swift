// swift-tools-version: 5.9
import PackageDescription

// Рендерер декларативных схем. Отдельный пакет, потому что нужен двоим:
// экрану фильтров в поиске и блоку атрибутов в карточке.

let package = Package(
    name: "KufarSchemaKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SchemaKit", targets: ["SchemaKit"])
    ],
    dependencies: [
        .package(id: "kufar.DesignTokens", from: "1.0.0"),
        .package(id: "kufar.DesignComponents", from: "1.0.0"),
        .package(id: "kufar.Foundation", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "SchemaKit",
            dependencies: [
                .product(name: "DesignTokens", package: "kufar.DesignTokens"),
                .product(name: "DesignComponents", package: "kufar.DesignComponents"),
                .product(name: "SharedKernel", package: "kufar.Foundation")
            ]
        )
    ]
)
