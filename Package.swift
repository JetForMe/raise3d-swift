// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "raise3d",
	platforms: [.macOS(.v13)],
	dependencies:
	[
		.package(url: "https://github.com/apple/swift-argument-parser",						from: "1.0.0"),
	],
	targets:
	[
		.executableTarget(
			name: "raise3d",
			dependencies:
			[
				.product(name: "ArgumentParser", 			package: "swift-argument-parser"),
			]),
	]
)
