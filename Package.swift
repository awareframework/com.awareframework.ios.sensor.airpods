// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "com.awareframework.ios.sensor.airpods",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "com.awareframework.ios.sensor.airpods",
            targets: [
                "com.awareframework.ios.sensor.airpods"
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/awareframework/com.awareframework.ios.core.git", from: "1.1.0")
    ],
    targets: [
        .target(
            name: "com.awareframework.ios.sensor.airpods",
            dependencies: [
                .product(name: "com.awareframework.ios.core", package: "com.awareframework.ios.core", condition: .when(platforms: [.iOS]))
            ],
            path: "Sources/com.awareframework.ios.sensor.airpods"
        ),
        .testTarget(
            name: "com.awareframework.ios.sensor.airpodsTests",
            dependencies: [
                "com.awareframework.ios.sensor.airpods",
                .product(name: "com.awareframework.ios.core", package: "com.awareframework.ios.core", condition: .when(platforms: [.iOS]))
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
