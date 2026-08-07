// swift-tools-version: 5.9
import PackageDescription

// Чистый Swift без SwiftUI. Поэтому платформенная планка ниже остальных
// пакетов: этот код переиспользуется расширениями, виджетом и часами.

let package = Package(
    name: "KufarFoundation",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "SharedKernel", targets: ["SharedKernel"]),
        // Контракт транспорта отдельным продуктом от реализации: адаптеру
        // нужен только он, и тянуть ради этого APIClient незачем.
        .library(name: "NetworkingInterface", targets: ["NetworkingInterface"]),
        .library(name: "Networking", targets: ["Networking"]),
        .library(name: "NetworkingTesting", targets: ["NetworkingTesting"])
    ],
    targets: [
        .target(name: "SharedKernel"),
        .target(name: "NetworkingInterface"),
        .target(name: "Networking", dependencies: ["NetworkingInterface"]),
        .target(name: "NetworkingTesting", dependencies: ["NetworkingInterface"])
    ]
)
