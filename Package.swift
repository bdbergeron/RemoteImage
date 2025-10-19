// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "RemoteImage",
  platforms: [
    .macOS(.v13),
    .iOS(.v16),
  ],
  products: [
    .library(name: "RemoteImage", targets: ["RemoteImage"]),
  ],
  dependencies: [
    .package(url: "https://github.com/bdbergeron/Stubby", .upToNextMajor(from: "1.0.0")),
    .package(url: "https://github.com/nalexn/ViewInspector", .upToNextMajor(from: "0.10.0")),
    .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.0"),
  ],
  targets: [
    .target(
      name: "RemoteImage",
      dependencies: []),
    .testTarget(
      name: "RemoteImageTests",
      dependencies: [
        .target(name: "RemoteImage"),
        .product(name: "ViewInspector", package: "ViewInspector"),
        .product(name: "Stubby", package: "Stubby"),
      ],
      resources: [
        .process("Resources"),
      ]),
  ]
)
