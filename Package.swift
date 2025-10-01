// swift-tools-version: 6.2
import PackageDescription
import CompilerPluginSupport
import Foundation

#if os(Windows)
let includePHPXCFramework = false
let phpSrc = ProcessInfo.processInfo.environment["PHP_SRC_ROOT"] ?? "D:/dev/php-src"
let phpLib = ProcessInfo.processInfo.environment["PHP_LIB_ROOT"] ?? "D:/dev/php-src/libs"
#else
let includePHPXCFramework = true
let phpSrc = "build/php-src"
let phpLib = ""
#endif

var targets: [Target] = [

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
                "-Xcc","-I","-Xcc","PHP.xcframework/macos-arm64/Headers",
                "-Xcc","-I","-Xcc","PHP.xcframework/macos-arm64/Headers/main",
                "-Xcc","-I","-Xcc","PHP.xcframework/macos-arm64/Headers/Zend",
                "-Xcc","-I","-Xcc","PHP.xcframework/macos-arm64/Headers/TSRM",
            ], .when(platforms: [.macOS])),
            .unsafeFlags([
                "-Xcc","-I","-Xcc","PHP.xcframework/ios-arm64/Headers",
                "-Xcc","-I","-Xcc","PHP.xcframework/ios-arm64/Headers/main",
                "-Xcc","-I","-Xcc","PHP.xcframework/ios-arm64/Headers/Zend",
                "-Xcc","-I","-Xcc","PHP.xcframework/ios-arm64/Headers/TSRM",
            ], .when(platforms: [.iOS])),
        ]
    ),

    .target(
        name: "CSwiftPHP",
        dependencies: [
            .target(name: "CPHP", condition: .when(platforms: [.linux, .windows])),
        ],
        path: "Sources/CSwiftPHP",
        publicHeadersPath: ".",
        cSettings: [
            .unsafeFlags([
                "-I","PHP.xcframework/macos-arm64/Headers",
                "-I","PHP.xcframework/macos-arm64/Headers/main",
                "-I","PHP.xcframework/macos-arm64/Headers/Zend",
                "-I","PHP.xcframework/macos-arm64/Headers/TSRM",
            ], .when(platforms: [.macOS])),
            .unsafeFlags([
                "-I","PHP.xcframework/ios-arm64/Headers",
                "-I","PHP.xcframework/ios-arm64/Headers/main",
                "-I","PHP.xcframework/ios-arm64/Headers/Zend",
                "-I","PHP.xcframework/ios-arm64/Headers/TSRM",
            ], .when(platforms: [.iOS])),
            .unsafeFlags([
                "-I", phpSrc,
                "-I", "\(phpSrc)/main",
                "-I", "\(phpSrc)/Zend",
                "-I", "\(phpSrc)/TSRM",
            ], .when(platforms: [.linux])),
            .define("ZEND_WIN32", .when(platforms: [.windows])),
            .define("PHP_WIN32",  .when(platforms: [.windows])),
            .define("WIN32",      .when(platforms: [.windows])),
            .define("_WIN32",     .when(platforms: [.windows])),
            .define("_WINDOWS",   .when(platforms: [.windows])),
            .define("ZTS",        .when(platforms: [.windows])),
            .define("ZEND_DEBUG", to: "0", .when(platforms: [.windows])),
            .unsafeFlags([
                "-I", phpSrc,
                "-I", "\(phpSrc)/main",
                "-I", "\(phpSrc)/Zend",
                "-I", "\(phpSrc)/TSRM",
                "-I", "\(phpSrc)/win32",
                "-fno-builtin",
            ], .when(platforms: [.windows])),
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

    .systemLibrary(
        name: "CPHP",
        path: "Sources/CPHP",
        pkgConfig: "php",
        providers: [.apt(["php8.4-dev","libphp8.4-embed"])]
    ),

    .target(
        name: "SwiftPHPExtension",
        dependencies: [
            "PHPCore",
            .target(name: "CPHP", condition: .when(platforms: [.linux, .windows])),
        ],
        path: "Sources/SwiftPHPExtension",
        cSettings: [
            .define("ZEND_WIN32", .when(platforms: [.windows])),
            .define("PHP_WIN32",  .when(platforms: [.windows])),
            .define("WIN32",      .when(platforms: [.windows])),
            .define("_WIN32",     .when(platforms: [.windows])),
            .define("_WINDOWS",   .when(platforms: [.windows])),
            .define("ZTS",        .when(platforms: [.macOS, .iOS])),
            .define("ZEND_DEBUG", .when(platforms: [.macOS, .iOS])),
            .define("ZEND_DEBUG", to: "0", .when(platforms: [.windows])),
            .unsafeFlags([
                "-I", phpSrc,
                "-I", "\(phpSrc)/main",
                "-I", "\(phpSrc)/Zend",
                "-I", "\(phpSrc)/TSRM",
                "-I", "\(phpSrc)/win32",
            ], .when(platforms: [.windows])),
        ],
        swiftSettings: [
            .define("ZEND_DEBUG", .when(platforms: [.macOS, .iOS])),
            .define("ZTS", .when(platforms: [.macOS, .iOS])),
            .unsafeFlags([
                "-Xcc","-I","-Xcc","PHP.xcframework/macos-arm64/Headers",
                "-Xcc","-I","-Xcc","PHP.xcframework/macos-arm64/Headers/main",
                "-Xcc","-I","-Xcc","PHP.xcframework/macos-arm64/Headers/Zend",
                "-Xcc","-I","-Xcc","PHP.xcframework/macos-arm64/Headers/TSRM",
            ], .when(platforms: [.macOS])),
            .unsafeFlags([
                "-Xcc","-I","-Xcc","PHP.xcframework/ios-arm64/Headers",
                "-Xcc","-I","-Xcc","PHP.xcframework/ios-arm64/Headers/main",
                "-Xcc","-I","-Xcc","PHP.xcframework/ios-arm64/Headers/Zend",
                "-Xcc","-I","-Xcc","PHP.xcframework/ios-arm64/Headers/TSRM",
            ], .when(platforms: [.iOS])),
        ],
        linkerSettings: [
            .unsafeFlags(["-Xlinker","-undefined","-Xlinker","dynamic_lookup"], .when(platforms: [.macOS, .iOS])),
            .unsafeFlags(["-L", phpLib, "\(phpLib)/php8.lib"], .when(platforms: [.windows])),
        ]
    ),
]

if includePHPXCFramework {
    targets.append(.binaryTarget(name: "PHP", path: "PHP.xcframework"))
}

let package = Package(
    name: "SwiftPHP",
    platforms: [.macOS(.v14), .iOS(.v13)],
    products: [
        .library(name: "PHP", targets: ["PHPCore"]),
        .library(name: "SwiftPHPExtension", type: .dynamic, targets: ["SwiftPHPExtension"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest"),
    ],
    targets: targets
)