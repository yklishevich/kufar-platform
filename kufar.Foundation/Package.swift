// swift-tools-version: 5.9
import PackageDescription

// Чистый Swift без SwiftUI. Поэтому платформенная планка ниже остальных
// пакетов: этот код переиспользуется расширениями, виджетом и часами.

let package = Package(
    name: "KufarFoundation",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "SharedKernel", targets: ["SharedKernel"]),
        .library(name: "Networking", targets: ["Networking"])
    ],
    targets: [
        .target(name: "SharedKernel"),
        .target(name: "Networking")
    ]
)
