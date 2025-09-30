// swift-tools-version: 6.0

import PackageDescription
import CompilerPluginSupport
import Foundation

let package = Package(
    name: "SwiftPHP",
    platforms: [
        .macOS(.v14),
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "PHP",
            targets: ["SwiftPHP"]
        ),
        .library(
            name: "SwiftPHPExtension",
            type: .dynamic,
            targets: ["SwiftPHPExtension"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest"),
    ],
    targets: [
        .target(
            name: "PHPCore",
            dependencies: [
                "CSwiftPHP",
                .target(name: "CPHP", condition: .when(platforms: [.linux, .windows])),
            ],
            path: "Sources/PHPCore",
            swiftSettings: [
                .define("ZTS", .when(platforms: [.macOS, .iOS])),
                .unsafeFlags([
                    "-Xcc", "-I", "-Xcc", "PHP.xcframework/macos-arm64/Headers",
                    "-Xcc", "-I", "-Xcc", "PHP.xcframework/macos-arm64/Headers/main",
                    "-Xcc", "-I", "-Xcc", "PHP.xcframework/macos-arm64/Headers/Zend",
                    "-Xcc", "-I", "-Xcc", "PHP.xcframework/macos-arm64/Headers/TSRM"
                ], .when(platforms: [.macOS])),
                .unsafeFlags([
                    "-Xcc", "-I", "-Xcc", "PHP.xcframework/ios-arm64/Headers",
                    "-Xcc", "-I", "-Xcc", "PHP.xcframework/ios-arm64/Headers/main",
                    "-Xcc", "-I", "-Xcc", "PHP.xcframework/ios-arm64/Headers/Zend",
                    "-Xcc", "-I", "-Xcc", "PHP.xcframework/ios-arm64/Headers/TSRM"
                ], .when(platforms: [.iOS])),
            ]
        ),
        
        .target(
            name: "SwiftPHP",
            dependencies: [
                "PHPCore",
                .target(name: "PHP", condition: .when(platforms: [.macOS, .iOS])),
            ],
            path: "Sources/SwiftPHP"
        ),

        .target(
            name: "CSwiftPHP",
            dependencies: [
                .target(name: "CPHP", condition: .when(platforms: [.linux, .windows])),
            ],
            path: "Sources/CSwiftPHP",
            publicHeadersPath: ".",
            cSettings: [
                .unsafeFlags(["-DZTS"], .when(platforms: [.macOS, .iOS])),
                .unsafeFlags([
                    "-I", "PHP.xcframework/macos-arm64/Headers",
                    "-I", "PHP.xcframework/macos-arm64/Headers/main",
                    "-I", "PHP.xcframework/macos-arm64/Headers/Zend",
                    "-I", "PHP.xcframework/macos-arm64/Headers/TSRM"
                ], .when(platforms: [.macOS])),
                .unsafeFlags([
                    "-I", "PHP.xcframework/ios-arm64/Headers",
                    "-I", "PHP.xcframework/ios-arm64/Headers/main",
                    "-I", "PHP.xcframework/ios-arm64/Headers/Zend",
                    "-I", "PHP.xcframework/ios-arm64/Headers/TSRM"
                ], .when(platforms: [.iOS])),
                .unsafeFlags([
                    "-I", ProcessInfo.processInfo.environment["PHP_SRC_ROOT"] ?? "build/php-src",
                    "-I", "\(ProcessInfo.processInfo.environment["PHP_SRC_ROOT"] ?? "build/php-src")/main",
                    "-I", "\(ProcessInfo.processInfo.environment["PHP_SRC_ROOT"] ?? "build/php-src")/Zend",
                    "-I", "\(ProcessInfo.processInfo.environment["PHP_SRC_ROOT"] ?? "build/php-src")/TSRM"
                ], .when(platforms: [.linux, .windows])),
            ]
        ),

        .binaryTarget(
            name: "PHP",
            path: "PHP.xcframework"
        ),

        .systemLibrary(
            name: "CPHP",
            path: "Sources/CPHP",
            pkgConfig: "php",
            providers: [
                .apt(["php8.4-dev", "libphp8.4-embed"]),
            ]
        ),
        
        .target(
            name: "SwiftPHPExtension",
            dependencies: [
                // --- FIXED: Dependency restored to PHPCore ---
                "PHPCore",
                .target(name: "CPHP", condition: .when(platforms: [.linux, .windows]))
            ],
            path: "Sources/SwiftPHPExtension",
            swiftSettings: [
                .define("ZTS", .when(platforms: [.macOS, .iOS])),
                 .unsafeFlags([
                    "-Xcc", "-I", "-Xcc", "PHP.xcframework/macos-arm64/Headers",
                    "-Xcc", "-I", "-Xcc", "PHP.xcframework/macos-arm64/Headers/main",
                    "-Xcc", "-I", "-Xcc", "PHP.xcframework/macos-arm64/Headers/Zend",
                    "-Xcc", "-I", "-Xcc", "PHP.xcframework/macos-arm64/Headers/TSRM"
                ], .when(platforms: [.macOS])),
                .unsafeFlags([
                    "-Xcc", "-I", "-Xcc", "PHP.xcframework/ios-arm64/Headers",
                    "-Xcc", "-I", "-Xcc", "PHP.xcframework/ios-arm64/Headers/main",
                    "-Xcc", "-I", "-Xcc", "PHP.xcframework/ios-arm64/Headers/Zend",
                    "-Xcc", "-I", "-Xcc", "PHP.xcframework/ios-arm64/Headers/TSRM"
                ], .when(platforms: [.iOS])),
            ],
            linkerSettings: [
                .unsafeFlags(["-DZTS"], .when(platforms: [.macOS, .iOS])),
                .unsafeFlags(["-Xlinker", "-undefined", "-Xlinker", "dynamic_lookup"], .when(platforms: [.macOS, .iOS]))
            ]
        )
    ]
)

