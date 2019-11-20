// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Sundial",
    platforms: [
      .iOS(.v9)
    ],
    products: [
      .library(name: "Sundial", targets: ["Sundial"])
    ],
    dependencies: [
      .package(url: "https://github.com/netcosports/Astrolabe.git", .upToNextMajor(from: "5.1.0"))
    ],
    targets: [
      .target(name: "Sundial", dependencies: ["Astrolabe"], path: "./Sources")
    ],
    swiftLanguageVersions: [.v5]
)
