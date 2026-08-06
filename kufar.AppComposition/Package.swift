// swift-tools-version: 5.9
import PackageDescription

// Композиционный корень: единственное место, где встречаются реализации.
// Ни одного import *UI — assembly возвращают непрозрачные типы.

let package = Package(
    name: "KufarAppComposition",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "AppComposition", targets: ["AppComposition"])
    ],
    dependencies: [
        .package(id: "kufar.AppFeature", from: "1.0.0"),
        .package(id: "kufar.Search", from: "1.0.0"),
        .package(id: "kufar.Posting", from: "1.0.0"),
        .package(id: "kufar.Goods", from: "1.0.0"),
        .package(id: "kufar.Auto", from: "1.0.0"),
        .package(id: "kufar.Identity", from: "1.0.0"),
        .package(id: "kufar.IdentityContracts", from: "1.0.0"),
        .package(id: "kufar.Foundation", from: "1.0.0"),
        .package(id: "kufar.Navigation", from: "1.0.0"),
        .package(id: "kufar.Analytics", from: "1.0.0"),
        .package(id: "kufar.ListingKit", from: "1.0.0"),
        .package(id: "kufar.CatalogContracts", from: "1.0.0"),
        .package(id: "kufar.PostingContracts", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "AppComposition",
            dependencies: [
                .product(name: "AppFeature", package: "kufar.AppFeature"),
                .product(name: "Search", package: "kufar.Search"),
                .product(name: "Posting", package: "kufar.Posting"),
                .product(name: "Goods", package: "kufar.Goods"),
                .product(name: "Auto", package: "kufar.Auto"),
                .product(name: "Profile", package: "kufar.Identity"),
                .product(name: "Auth", package: "kufar.Identity"),
                .product(name: "AnalyticsImpl", package: "kufar.Analytics"),
                .product(name: "AnalyticsAPI", package: "kufar.Analytics"),
                .product(name: "Networking", package: "kufar.Foundation"),
                .product(name: "Navigation", package: "kufar.Navigation"),
                .product(name: "SharedKernel", package: "kufar.Foundation"),
                .product(name: "SessionInterface", package: "kufar.IdentityContracts"),
                // Только ради типа ListingRowAccessory: корень собирает слот
                // строки ленты, но ни одного экрана по-прежнему не знает.
                .product(name: "ListingKit", package: "kufar.ListingKit"),
                // Слот шага подачи: корню нужны CatalogCategory и PostingDraft,
                // чтобы написать switch по вертикали. Оба — контракты.
                .product(name: "CatalogContracts", package: "kufar.CatalogContracts"),
                .product(name: "PostingInterface", package: "kufar.PostingContracts")
            ]
        ),
        .testTarget(name: "ArchitectureTests")
    ]
)
