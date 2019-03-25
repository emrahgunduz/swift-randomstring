// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "rstring",
    products: [
      .executable(name: "rstring", targets: ["rstring"]),
    ],
    dependencies: [
      .package(url: "git@github.com:emrahgunduz/swift-randomstring-information.git", from: "1.0.0"),
      .package(url: "git@github.com:emrahgunduz/swift-randomstring-log.git", from: "1.0.0"),
      .package(url: "git@github.com:emrahgunduz/swift-randomstring-trie.git", from: "1.1.0"),
      .package(url: "git@github.com:emrahgunduz/swift-randomstring-signals.git", from: "1.0.0"),
    ],
    targets: [
      .target(name: "rstring", dependencies: ["Information", "Trie", "Log", "Signals"])
    ]
)