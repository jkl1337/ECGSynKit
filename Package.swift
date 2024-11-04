// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ECGSynKit",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ECGSynKit",
            targets: ["ECGSynKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.0"),
        .package(url: "https://github.com/jkl1337/SwiftPFFFT", branch: "master"),
        .package(url: "https://github.com/jkl1337/swift-odeint", branch: "master"),
    ],
    targets: [
        .target(
            name: "ECGSynKit",
            dependencies: [
                .product(name: "PFFFT", package: "SwiftPFFFT"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "OdeInt", package: "swift-odeint"),
            ]
        ),
        .testTarget(
            name: "ECGSynKitTests",
            dependencies: ["ECGSynKit"]
        ),
    ]
)
