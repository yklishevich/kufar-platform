// swift-tools-version: 5.9
import PackageDescription

// Каркас карточки со слотами. Про SchemaKit НЕ знает: блок атрибутов
// приходит в слот от вертикали. Два пакета одного репозитория
// не обязаны зависеть друг от друга.

let package = Package(
    name: "KufarListingKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ListingKit", targets: ["ListingKit"])
    ],
    dependencies: [
        .package(id: "kufar.DesignTokens", from: "1.0.0"),
        .package(id: "kufar.DesignComponents", from: "1.0.0"),
        .package(id: "kufar.Foundation", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "ListingKit",
            dependencies: [
                .product(name: "DesignTokens", package: "kufar.DesignTokens"),
                .product(name: "DesignComponents", package: "kufar.DesignComponents"),
                .product(name: "SharedKernel", package: "kufar.Foundation")
            ]
        )
    ]
)
