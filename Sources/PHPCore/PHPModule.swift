import Foundation

public let STANDARD_MODULE_HEADER_EX = (
    size: MemoryLayout<zend_module_entry>.size,
    zendApiNo: ZEND_MODULE_API_NO,
    zendDebug: ZEND_DEBUG,
    usingZTS: USING_ZTS
)

public let STANDARD_MODULE_PROPERTIES_EX: (
    globalsSize: Int,
    globalsCtor: (@Sendable (UnsafeMutableRawPointer) -> Void)?,
    globalsDtor: (@Sendable (UnsafeMutableRawPointer) -> Void)?,
    postDeactivate: (@Sendable () -> Int32)?,
    moduleStartup: String
) = (
    globalsSize: 0,
    globalsCtor: nil,
    globalsDtor: nil,
    postDeactivate: nil,
    moduleStartup: ZEND_MODULE_BUILD_ID
)



// public let NO_MODULE_GLOBALS = (
//     globalsSize: 0,
//     globalsCtor: nil,
//     globalsDtor: nil,
//     postDeactivate: nil
// )
