// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FFPhotosLibrary",
    platforms: [.iOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "FFPhotosLibrary",
            targets: ["FFPhotosLibrary"]),
    ],
    dependencies: [
        .package(url: "https://github.com/caochengfei/FFUITool.git", from: "0.2.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "FFPhotosLibrary",
            dependencies: [.product(name: "FFUITool", package: "FFUITool")],
            path: "FFPhotosLibrary/Classes"

        ),
//        .testTarget(
//            name: "FFPhotosLibraryTests",
//            dependencies: ["FFPhotosLibrary"]),
    ]
)
