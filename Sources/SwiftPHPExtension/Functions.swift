import PHPCore
import Foundation

@MainActor
public let arginfo_confirm_raylib_compiled: [zend_internal_arg_info] =
    ZEND_BEGIN_ARG_INFO_EX(name: "", return_reference: false, required_num_args: 0)
@_cdecl("zif_confirm_raylib_compiled")
public func zif_confirm_raylib_compiled(
    _ execute_data: UnsafeMutablePointer<zend_execute_data>?, 
    _ return_value: UnsafeMutablePointer<zval>?
) {
    guard let return_value = return_value else {
        return
    }

    let message = "Congratulations! You have successfully compiled the Swift extension."

    let zendStrOpt = message.withCString { cstr in
        return zend_string_init(cstr, strlen(cstr), false)
    }

    guard let zendStr = zendStrOpt else {
        return
    }

    RETURN_STR(zendStr, return_value)
}

@MainActor
public let arginfo_raylib_hello: [zend_internal_arg_info] =
    ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(name: "raylib_hello", return_reference: false, required_num_args: 0, type: UInt32(IS_STRING), allow_null: false)
    + [ZEND_ARG_TYPE_INFO_WITH_DEFAULT_VALUE(pass_by_ref: false, name: "str", type_hint: UInt32(IS_STRING), allow_null: true, default_value: "\"\"")]
@_cdecl("zif_raylib_hello")
public func zif_raylib_hello(execute_data: UnsafeMutablePointer<zend_execute_data>?, return_value: UnsafeMutablePointer<zval>?) {
    var var_str: UnsafeMutablePointer<CChar>? = nil
    var var_len: Int = 0

    guard let return_value = return_value else {
        return
    }

    do {
        guard var state = ZEND_PARSE_PARAMETERS_START(min: 0, max: 1, execute_data: execute_data) else {
            return
        }
        
        Z_PARAM_OPTIONAL(state: &state)
        
        try Z_PARAM_STRING_OR_NULL(state: &state, dest: &var_str, destLen: &var_len)

        try ZEND_PARSE_PARAMETERS_END(state: state)

    } catch {
        return
    }

    let swiftString: String
    if let cString = var_str {
        // A string (even an empty one) was passed, so we use it.
        swiftString = String(cString: cString)
    } else {
        // A `null` was passed or the argument was omitted. Return an empty string
        RETURN_STR(ZSTR_EMPTY_ALLOC(), return_value)
        return
    }

    let message = "Hello \(swiftString)"

    let retval: UnsafeMutablePointer<zend_string>? = message.withCString { messagePtr in
        return zend_string_init(messagePtr, message.utf8.count, false)
    }

    if let resultString: UnsafeMutablePointer<zend_string> = retval {
        RETURN_STR(resultString, return_value)
    }
}

@MainActor
public func functions_add_entries(builder: inout FunctionListBuilder) {
    builder.add(name: "confirm_raylib_compiled", handler: zif_confirm_raylib_compiled, arg_info: arginfo_confirm_raylib_compiled)
    builder.add(name: "raylib_hello", handler: zif_raylib_hello, arg_info: arginfo_raylib_hello)
}