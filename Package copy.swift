// Package.swift
// swift-tools-version: 6.2
import PackageDescription
import CompilerPluginSupport
import Foundation

let env = ProcessInfo.processInfo.environment

#if os(Windows)
let includePHPXCFramework = false
let phpSrcEnv = env["PHP_SRC_ROOT"] ?? "D:/dev/php-src"
let phpLib = env["PHP_LIB_ROOT"] ?? "D:/dev/php-src/libs"
#else
let includePHPXCFramework = true
let phpSrcEnv = env["PHP_INCLUDE_BASE"] ?? "build/php-src"
let phpLib = ""
#endif

let isZTS: Bool = { if let v = env["ZTS"] { return v == "1" || v.lowercased() == "true" } ; return false }()
let isZendDebug: Bool = { if let v = env["ZEND_DEBUG"] { return v == "1" || v.lowercased() == "true" } ; return false }()

func ztsCDefines() -> [CSetting] { isZTS ? [.define("ZTS")] : [] }
func ztsSwiftDefines() -> [SwiftSetting] { isZTS ? [.define("ZTS_SWIFT")] : [] }
func zendDebugCDefines() -> [CSetting] { isZendDebug ? [.define("ZEND_DEBUG")] : [] }
func zendDebugSwiftDefines() -> [SwiftSetting] { isZendDebug ? [.define("ZEND_DEBUG_SWIFT")] : [] }

let linuxCIncludePaths: [CSetting] = [
    .unsafeFlags([
        "-I", phpSrcEnv,
        "-I", "\(phpSrcEnv)/main",
        "-I", "\(phpSrcEnv)/Zend",
        "-I", "\(phpSrcEnv)/TSRM",
    ], .when(platforms: [.linux]))
]

let winBaseDefs: [CSetting] = [
    .define("ZEND_WIN32", .when(platforms: [.windows])),
    .define("PHP_WIN32",  .when(platforms: [.windows])),
    .define("WIN32",      .when(platforms: [.windows])),
    .define("_WIN32",     .when(platforms: [.windows])),
    .define("_WINDOWS",   .when(platforms: [.windows]))
]

var targets: [Target] = [
    .target(
        name: "CSwiftPHP",
        path: "Sources/CSwiftPHP",
        publicHeadersPath: ".",
        cSettings: linuxCIncludePaths + winBaseDefs + ztsCDefines() + zendDebugCDefines(),
        swiftSettings: ztsSwiftDefines() + zendDebugSwiftDefines()
    ),
    .target(
        name: "PHPCore",
        dependencies: ["CSwiftPHP"],
        path: "Sources/PHPCore",
        cSettings: linuxCIncludePaths + winBaseDefs + ztsCDefines() + zendDebugCDefines(),
        swiftSettings: ztsSwiftDefines() + zendDebugSwiftDefines()
    ),
    .target(
        name: "SwiftPHPExtension",
        dependencies: ["PHPCore","CSwiftPHP"],
        path: "Sources/SwiftPHPExtension",
        cSettings: linuxCIncludePaths + winBaseDefs + ztsCDefines() + zendDebugCDefines(),
        swiftSettings: ztsSwiftDefines() + zendDebugSwiftDefines(),
        linkerSettings: [
            .unsafeFlags(["-Xlinker","-undefined","-Xlinker","dynamic_lookup"], .when(platforms: [.macOS, .iOS])),
            .unsafeFlags(["-L\(phpLib)", "\(phpLib)/php8.lib"], .when(platforms: [.windows]))
        ]
    )
]

if includePHPXCFramework {
    targets.append(.binaryTarget(name: "PHP", path: "PHP.xcframework"))
}

let package = Package(
    name: "SwiftPHP",
    platforms: [.macOS(.v14), .iOS(.v13)],
    products: [
        .library(name: "SwiftPHPExtension", type: .dynamic, targets: ["SwiftPHPExtension"])
    ],
    targets: targets
)