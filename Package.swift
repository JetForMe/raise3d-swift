// swift-tools-version: 5.10

import PackageDescription

let package = Package(
	name: "Raise3D",
	platforms: [.macOS(.v13)],
	products:
	[
		.library(name: "Raise3DAPI", targets: ["Raise3DAPI"]),
		.executable(name: "raise3d", targets: ["CLI"])
	],
	dependencies:
	[
		.package(url: "https://github.com/apple/swift-argument-parser",		from: "1.0.0"),
		.package(url: "https://github.com/apple/swift-docc-plugin",			from: "1.0.0"),
	],
	targets:
	[
		.target(name: "Raise3DAPI", path: "Sources/API"),
		.executableTarget(
			name: "CLI",
			dependencies:
			[
				.product(name: "ArgumentParser", 			package: "swift-argument-parser"),
				.target(name: "Raise3DAPI"),
			]),
	]
)
