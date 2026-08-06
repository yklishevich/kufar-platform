// swift-tools-version: 5.9
import PackageDescription

// Корневой флоу. Зависит ТОЛЬКО от контрактных пакетов, поэтому
// собирается без сети, без единого *Data и без единой вертикали —
// и тесты внизу это доказывают.

let package = Package(
    name: "KufarAppFeature",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "AppFeature", targets: ["AppFeature"])
    ],
    dependencies: [
        .package(id: "kufar.SearchContracts", from: "1.0.0"),
        .package(id: "kufar.PostingContracts", from: "1.0.0"),
        .package(id: "kufar.GoodsContracts", from: "1.0.0"),
        .package(id: "kufar.AutoContracts", from: "1.0.0"),
        .package(id: "kufar.IdentityContracts", from: "1.0.0"),
        .package(id: "kufar.Foundation", from: "1.0.0"),
        .package(id: "kufar.Navigation", from: "1.0.0"),
        .package(id: "kufar.DesignTokens", from: "1.0.0"),
        .package(id: "kufar.DesignComponents", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "AppFeature",
            dependencies: [
                .product(name: "SharedKernel", package: "kufar.Foundation"),
                .product(name: "SessionInterface", package: "kufar.IdentityContracts"),
                .product(name: "SearchInterface", package: "kufar.SearchContracts"),
                .product(name: "PostingInterface", package: "kufar.PostingContracts"),
                .product(name: "GoodsInterface", package: "kufar.GoodsContracts"),
                .product(name: "AutoInterface", package: "kufar.AutoContracts"),
                .product(name: "ProfileInterface", package: "kufar.IdentityContracts"),
                .product(name: "Navigation", package: "kufar.Navigation"),
                .product(name: "DesignTokens", package: "kufar.DesignTokens"),
                .product(name: "DesignComponents", package: "kufar.DesignComponents"),
                .product(name: "SessionInterfaceTesting", package: "kufar.IdentityContracts")
            ]
        ),
        .testTarget(
            name: "AppFeatureTests",
            dependencies: [
                "AppFeature",
                .product(name: "SessionInterfaceTesting", package: "kufar.IdentityContracts"),
                .product(name: "SessionInterface", package: "kufar.IdentityContracts"),
                .product(name: "Navigation", package: "kufar.Navigation"),
                .product(name: "SharedKernel", package: "kufar.Foundation"),
                .product(name: "SearchInterface", package: "kufar.SearchContracts"),
                .product(name: "PostingInterface", package: "kufar.PostingContracts"),
                .product(name: "GoodsInterface", package: "kufar.GoodsContracts"),
                .product(name: "AutoInterface", package: "kufar.AutoContracts"),
                .product(name: "ProfileInterface", package: "kufar.IdentityContracts")
            ]
        )
    ]
)
