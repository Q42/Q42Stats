// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Q42Stats",
    platforms: [
        .iOS(.v12),
    ],
    products: [
        .library(name: "Q42Stats", targets: ["Q42Stats"])
    ],
    targets: [
        .target(name: "Q42Stats", dependencies: [])
    ]
)
