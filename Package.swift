// swift-tools-version: 6.2
import PackageDescription
import CompilerPluginSupport
import Foundation

#if os(Windows)
let includePHPXCFramework = false
// On Windows, read the absolute path from the environment variable.
let phpSrc = ProcessInfo.processInfo.environment["PHP_SRC_ROOT"]!
let phpLib = ProcessInfo.processInfo.environment["PHP_LIB_ROOT"]!
#else
let includePHPXCFramework = true
// On other platforms, use the default relative path.
let phpSrc = "build/php-src"
let phpLib = ""
#endif

var targets: [Target] = [
    .target(
        name: "PHPCore",
        dependencies: ["CSwiftPHP"],
        path: "Sources/PHPCore",
        cSettings: [
            .define("ZEND_WIN32", .when(platforms: [.windows])),
            .define("PHP_WIN32",  .when(platforms: [.windows])),
            // .define("ZTS",        .when(platforms: [.windows])), 
            .define("ZEND_DEBUG", to: "0", .when(platforms: [.windows])),
            .unsafeFlags([
                "-I", phpSrc,
                "-I", "\(phpSrc)/main",
                "-I", "\(phpSrc)/Zend",
                "-I", "\(phpSrc)/TSRM",
                "-I", "\(phpSrc)/win32",
                "-fno-builtin"
            ], .when(platforms: [.windows])),
        ],
        swiftSettings: [
            // Pass the PHP include paths to the Clang importer used by Swift
            // .unsafeFlags([
            //     "-Xcc", "-I\(phpSrc)",
            //     "-Xcc", "-I\(phpSrc)/main",
            //     "-Xcc", "-I\(phpSrc)/Zend",
            //     "-Xcc", "-I\(phpSrc)/TSRM",
            // ], .when(platforms: [.windows]))
        ]
    ),

    .target(
        name: "CSwiftPHP",
        dependencies: [],
        path: "Sources/CSwiftPHP",
        publicHeadersPath: ".",
        cSettings: [
            // --- C settings for Windows ---
            .define("ZEND_WIN32", .when(platforms: [.windows])),
            .define("PHP_WIN32",  .when(platforms: [.windows])),
            // .define("ZTS",        .when(platforms: [.windows])), 
            .define("ZEND_DEBUG", to: "0", .when(platforms: [.windows])),
            .unsafeFlags([
                "-I", phpSrc,
                "-I", "\(phpSrc)/main",
                "-I", "\(phpSrc)/Zend",
                "-I", "\(phpSrc)/TSRM",
                "-I", "\(phpSrc)/win32",
                "-fno-builtin"
            ], .when(platforms: [.windows])),

            // --- C settings for other platforms ---
            .headerSearchPath(phpSrc, .when(platforms: [.linux, .macOS, .iOS])),
            .headerSearchPath("\(phpSrc)/main", .when(platforms: [.linux, .macOS, .iOS])),
            .headerSearchPath("\(phpSrc)/Zend", .when(platforms: [.linux, .macOS, .iOS])),
            .headerSearchPath("\(phpSrc)/TSRM", .when(platforms: [.linux, .macOS, .iOS])),
        ]
    ),

    .systemLibrary(
        name: "CPHP",
        path: "Sources/CPHP",
        pkgConfig: "php",
        providers: [ .apt(["php8.4-dev","libphp8.4-embed"]) ]
    ),

    .target(
        name: "SwiftPHPExtension",
        dependencies: ["PHPCore"],
        path: "Sources/SwiftPHPExtension",
        swiftSettings: [
            .define("ZEND_WIN32", .when(platforms: [.windows])),
            .define("PHP_WIN32",  .when(platforms: [.windows])),
            // .define("ZTS",        .when(platforms: [.windows])),
            .define("ZEND_DEBUG", .when(platforms: [.windows])),
            .unsafeFlags([
                "-Xcc", "-I\(phpSrc)",
            //     "-Xcc", "-I\(phpSrc)/main",
                "-Xcc", "-I\(phpSrc)/Zend",
            //     "-Xcc", "-I\(phpSrc)/TSRM",
            //     "-Xcc", "-I\(phpSrc)/win32",
            ], .when(platforms: [.windows]))
        ],
        linkerSettings: [
              .unsafeFlags([
                  "-L", phpLib,
                  "\(phpLib)/php8.lib",
                  // "ws2_32.lib"
              ], .when(platforms: [.windows]))
          ]
    ),
]

print(phpLib)

if includePHPXCFramework {
    targets.append(.binaryTarget(name: "PHP", path: "PHP.xcframework"))
}

let package = Package(
    name: "SwiftPHP",
    platforms: [ .macOS(.v14), .iOS(.v13) ],
    products: [
        .library(name: "SwiftPHPExtension", type: .dynamic, targets: ["SwiftPHPExtension"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest"),
    ],
    targets: targets
)