+++
draft = false
title = 'Hello Swift'
+++

SwiftPHP is an effort to make PHP extensions in a safer language than C. Every PHP minor release contains memory leaks and buffer overflow which is easy to create in C, but harder to do the same in Swift. Swift also has great concurrency constructs, allowing you to access more compute in your native extensions.

I have chosen to make the API close to the C API for the first release so anyone coming from the C API or wants to use the C API for documentation can. It also makes migrating existing C extensions easier.

Why not "X-language"? Well, PHP's C-API is mostly C-Macros which is not possible to replicate in any other language other than C++. 

 - **Zig** - I have created a prototype to replicate many of the C-Macros however its too agressive in its C-Interop that its cause so much work and custom PHP C Core patches than its worth. Zig is also volitile in its API
 - **Rust** - Someone already did this work in Rust https://github.com/davidcole1340/ext-php-rs

## Supported PHP Versions

 - PHP 8.2 (Unsupported)
 - PHP 8.3 (Unsupported)
 - PHP 8.4 Thread-safe (ZTS)
 - PHP 8.5 (Pending Testing)

## Supported Operating Systems

 - MacOS ARM64
 - Windows 11 x64 and ARM64
 - Windows 11 ARM64
 - Linux x64
 - Linux ARM64

## Hello World Skeleton

```bash
# Compile extension
swift build -v --product SwiftPHPExtension

# Run PHP with custom extension
php -dextension=.build/arm64-apple-macosx/debug/libSwiftPHPExtension.dylib \
    -r 'var_dump(confirm_myext_compiled(), myext_hello());'

# Output:
# string(68) "Congratulations! You have successfully compiled the Swift extension."
# string(0) ""
```

### PHP function:
```php
function myext_hello(?string $str): string
{
    if ($str === null) {
        return "";
    }
    
    return "Hello " . $str;
}
```

### Native PHP Extension version in Swift
```swift
import PHPCore
import Foundation

// PHP function argument register for type checking
@MainActor
public let arginfo_myext_hello: [zend_internal_arg_info] =
    ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(
        name: "myext_hello", 
        return_reference: false, 
        required_num_args: 0, // All parameters are optional
        type: UInt32(IS_STRING), 
        allow_null: false
        )
    + [ZEND_ARG_TYPE_INFO_WITH_DEFAULT_VALUE(
        pass_by_ref: false, 
        name: "str", 
        type_hint: UInt32(IS_STRING), 
        allow_null: true,
        default_value: "\"\"")]

// Your Swift function to register
@_cdecl("zif_myext_hello")
public func zif_myext_hello(
    execute_data: UnsafeMutablePointer<zend_execute_data>?, 
    return_value: UnsafeMutablePointer<zval>?) {
    // Ensure return value is initialized (redundent but needed)
    guard let return_value: UnsafeMutablePointer<zval> = return_value else {
        return
    }

    // Safely do parameter capture
    var var_str: UnsafeMutablePointer<CChar>? = nil
    var var_len: Int = 0
    do {
        // Start parameter parsing
        guard var state: ParseState = ZEND_PARSE_PARAMETERS_START(
            min: 0, max: 1, execute_data: execute_data
        ) else {
            return
        }
        
        // Any parameter parsed after this is optional
        Z_PARAM_OPTIONAL(state: &state)
        
        // If this was not optional Z_PARAM_STRING 
        // would be the correct call instead.
        try Z_PARAM_STRING_OR_NULL(
            state: &state, dest: &var_str, destLen: &var_len
        )
        
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

    // Format Swift String
    let message: String = "Hello \(swiftString)"

    // Convert back to PHP String
    let retval: UnsafeMutablePointer<zend_string>? = message.withCString { 
        return zend_string_init(messagePtr, message.utf8.count, false)
    }

    // Return the PHP String
    if let resultString: UnsafeMutablePointer<zend_string> = retval {
        RETURN_STR(resultString, return_value)
    }
}

// Global pointers to hold data that will persist
@MainActor var myext_functions_ptr: UnsafeMutablePointer<zend_function_entry>? = nil
@MainActor var myext_ini_entries_ptr: UnsafeMutablePointer<zend_ini_entry>? = nil
@MainActor var myext_deps_ptr: UnsafeMutablePointer<zend_module_dep>? = nil
@MainActor var myextModule_ptr: UnsafeMutablePointer<zend_module_entry>? = nil 
@MainActor var myext_globals_id: ts_rsrc_id = 0

struct myextGlobals {
    var someGlobalVariable: Int = 0
}

@_cdecl("zm_startup_myext")
func zm_startup_myext(type: Int32, module_number: Int32) -> Int32 {
    return Int32(SUCCESS.rawValue)
}

@_cdecl("zm_shutdown_myext")
func zm_shutdown_myext(type: Int32, module_number: Int32) -> Int32 {
    return Int32(SUCCESS.rawValue)
}

@_cdecl("zm_activate_myext")
func zm_activate_myext(type: Int32, module_number: Int32) -> Int32 {
    return Int32(SUCCESS.rawValue)
}

@_cdecl("zm_deactivate_myext")
func zm_deactivate_myext(type: Int32, module_number: Int32) -> Int32 {
    return Int32(SUCCESS.rawValue)
}

@_cdecl("zm_info_myext")
func zm_info_myext(zend_module: UnsafeMutableRawPointer?) {
    print("Myext Module Version: 2.0.0")
}

@_cdecl("zm_globals_ctor_myext")
func zm_globals_ctor_myext(pointer: UnsafeMutableRawPointer?) {
    let globals = pointer!.bindMemory(to: myextGlobals.self, capacity: 1)
    globals.pointee.someGlobalVariable = 42
}

@_cdecl("zm_globals_dtor_myext")
func zm_globals_dtor_myext(pointer: UnsafeMutableRawPointer?) {
    // Optional cleanup code for globals
}


@_cdecl("get_module")
@MainActor
func get_module() -> UnsafeMutablePointer<zend_module_entry> {
    // Allocate memory for myext_functions
    var builder = FunctionListBuilder()

    // Add myext_hello
    builder.add(
        name: "myext_hello", 
        handler: zif_myext_hello, 
        arg_info: arginfo_myext_hello
    )

    // Convert to `UnsafeMutablePointer<zend_function_entry>`
    myext_functions_ptr = builder.build()
    
    // Create PHP Build String
    let version = strdup("1.0.0")
    let module_name = strdup("myext")
    var buildIdString = "API\(PHP_API_VERSION)"
    if ZTS != 0 {
        buildIdString += ",TS" // Thread Safe
    } else {
        buildIdString += ",NTS" // Non-Thread Safe
    }
    if PHP_DEBUG != 0 {
        buildIdString += ",debug"
    }
    let build_id = strdup(buildIdString)
    
    // Setup Custom INI settings
    myext_ini_entries_ptr = UnsafeMutablePointer<zend_ini_entry>.allocate(capacity: 1)
    myext_ini_entries_ptr?.initialize(to: zend_ini_entry())
    
    // Dependancies
    myext_deps_ptr = UnsafeMutablePointer<zend_module_dep>.allocate(capacity: 1)
    myext_deps_ptr?.initialize(to: zend_module_dep())
    
    myextModule_ptr = create_module_entry(
        module_name,
        version,
        myext_functions_ptr,
        zm_startup_myext,
        zm_shutdown_myext,
        zm_activate_myext,
        zm_deactivate_myext,
        zm_info_myext,
        MemoryLayout<myextGlobals>.size,
        &myext_globals_id,
        zm_globals_ctor_myext,
        zm_globals_dtor_myext,
        build_id
    )
    
    return myextModule_ptr!
}



```