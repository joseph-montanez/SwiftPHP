import Foundation

func ZEND_TOSTR(_ x: Int) -> String {
    return "\(x)"
}

#if ZTS
public let ZEND_BUILD_TS = ",TS"
#else
public let ZEND_BUILD_TS = ",NTS"
#endif

#if ZEND_DEBUG
public let ZEND_BUILD_DEBUG = ",debug"
#else
public let ZEND_BUILD_DEBUG = ""
#endif

#if ZEND_WIN32
public var ZEND_BUILD_SYSTEM: String {
    if let compilerID = PHP_COMPILER_ID {
        return "," + compilerID
    } else {
        return ""
    }
}
#else
public let ZEND_BUILD_SYSTEM = ""
#endif



let ZEND_BUILD_EXTRA = ""

public let ZEND_MODULE_BUILD_ID = "API\(ZEND_MODULE_API_NO)\(ZEND_BUILD_TS)\(ZEND_BUILD_DEBUG)\(ZEND_BUILD_SYSTEM)\(ZEND_BUILD_EXTRA)"
