// swift-tools-version:5.4
import PackageDescription

let package = Package(
    name: "Q42Stats",
    platforms: [
        .iOS(.v10),
    ],
    products: [
        .library(name: "Q42Stats", targets: ["Q42Stats"])
    ],
    targets: [
        .target(name: "Q42Stats", dependencies: [])
    ]
)
