// swift-tools-version: 5.9
import PackageDescription

// Router и AppRouter. Ни от чего не зависит: NavigationPath принимает
// любой Hashable, поэтому маршруты фич навигации неизвестны.

let package = Package(
    name: "KufarNavigation",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Navigation", targets: ["Navigation"])
    ],
    targets: [
        .target(name: "Navigation")
    ]
)
