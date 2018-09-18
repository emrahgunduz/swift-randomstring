// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "rstring",
    products: [
      .executable(name: "rstring", targets: ["rstring"]),
    ],
    dependencies: [
      .package(url: "git@git.markakod.com:nutella/random-code/library-information.git", from: "1.0.0"),
      .package(url: "git@git.markakod.com:nutella/random-code/library-log.git", from: "1.0.0"),
      .package(url: "git@git.markakod.com:nutella/random-code/library-trie.git", from: "1.0.0"),
    ],
    targets: [
      .target(name: "rstring", dependencies: ["Information", "Trie", "Log"])
    ]
)