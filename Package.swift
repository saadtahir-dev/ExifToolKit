// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ExifToolKit",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "ExifToolKit", targets: ["ExifToolKit"]),
    ],
    targets: [
        .target(
            name: "ExifToolKit",
            resources: [
                .copy("Resources/exiftool"),
                .copy("Resources/lib")
            ]
        ),
        .testTarget(
            name: "ExifToolKitTests",
            dependencies: ["ExifToolKit"],
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
