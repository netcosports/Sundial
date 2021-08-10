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
      .package(url: "https://github.com/netcosports/Astrolabe.git", .branch("kmm")),
      .package(url: "https://github.com/Quick/Nimble.git", .branch("main")),
      .package(url: "https://github.com/Quick/Quick.git", .branch("main"))
    ],
    targets: [
      .target(name: "Sundial", dependencies: ["Astrolabe"], path: "./Sources"),
      .testTarget(
        name: "SundialTests",
        dependencies: [
          "Sundial",
          "Nimble",
          "Quick"
        ]
      )
    ],
    swiftLanguageVersions: [.v5]
)
