// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "RemoteImage",
  platforms: [
    .iOS(.v16),
  ],
  products: [
    .library(name: "RemoteImage", targets: ["RemoteImage"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    .package(url: "https://github.com/nalexn/ViewInspector", .upToNextMajor(from: "0.9.7")),
    .package(name: "Stubby", path: "../Stubby"),
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
