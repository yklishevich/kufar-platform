// swift-tools-version: 5.9
import PackageDescription

// Генерируется из Figma. Отдельный пакет, потому что релизится
// своим циклом: правка токена не пересобирает компоненты.

let package = Package(
    name: "KufarDesignTokens",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "DesignTokens", targets: ["DesignTokens"])
    ],
    targets: [
        .target(name: "DesignTokens")
    ]
)
