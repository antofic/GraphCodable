// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let settings: [SwiftSetting] = [
	.define("USE_CWL_DEMANGLE"),
//	.unsafeFlags( [
//		"-enable-upcoming-feature", "ExistentialAny",
//		"-enable-upcoming-feature", "ForwardTrailingClosures"
//	])
]

let package = Package(
	name: "GraphCodable",
	platforms: [
		.macOS(.v11),
		.iOS(.v14),
		.watchOS(.v7),
		.tvOS(.v14)
	],
	products: [
		// Products define the executables and libraries a package produces, and make them visible to other packages.
		.library(
			name: "GraphCodable",
			targets: ["GraphCodable"]),
	],
	dependencies: [
		.package(url: "https://github.com/mattgallagher/CwlDemangle.git", from: "0.1.0"),
	],
	targets: [
		// Targets are the basic building blocks of a package. A target can define a module or a test suite.
		// Targets can depend on other targets in this package, and on products in packages this package depends on.
		.target(
			name: "GraphCodable",
			dependencies: [ "CwlDemangle" ],
			swiftSettings: settings
		),
		.testTarget(
			name: "GraphCodableTests",
			dependencies: ["GraphCodable"],
			swiftSettings: settings
		),
		.testTarget(
			name: "GraphCodablePerformanceTests",
			dependencies: ["GraphCodable"],
			swiftSettings: settings
		),
	],
	swiftLanguageVersions: [ .v5 ]
)
