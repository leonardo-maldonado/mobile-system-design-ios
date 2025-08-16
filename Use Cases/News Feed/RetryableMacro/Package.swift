// swift-tools-version: 5.10
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "RetryableMacro",
    platforms: [
        .iOS(.v15), .macOS(.v13)
    ],
    products: [
        .library(name: "RetryableMacro", targets: ["RetryableMacro"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "510.0.0"),
    ],
    targets: [
        .macro(
            name: "RetryableMacroMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(
            name: "RetryableMacro",
            dependencies: ["RetryableMacroMacros"]
        ),
        .testTarget(
            name: "RetryableMacroTests",
            dependencies: [
                "RetryableMacro",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ]
        ),
    ]
)