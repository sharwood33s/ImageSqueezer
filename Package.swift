// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ImageSqueezer",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ImageSqueezer", targets: ["ImageSqueezer"])
    ],
    targets: [
        .executableTarget(
            name: "ImageSqueezer",
            path: "Sources/ImageSqueezer"
        )
    ]
)
