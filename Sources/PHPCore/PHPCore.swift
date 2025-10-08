@preconcurrency @_exported import CSwiftPHP

// @_exported import CSwiftPHP

@inlinable
public func PHP_FE(
    _ name: String,
    _ handler: ZifHandler?,
    _ arg_info: [zend_internal_arg_info]?
) -> zend_function_entry {
    ZEND_FE(name: name, handler: handler, arg_info: arg_info)
}

@inlinable
public func PHP_ME(
    _ className: String,
    _ methodName: String,
    _ handler: ZifHandler?,
    _ arg_info: [zend_internal_arg_info]?,
    _ flags: Int32
) -> zend_function_entry {
    ZEND_ME(classname: className, name: methodName, handler: handler, arg_info: arg_info, flags: UInt32(flags))
}


public struct PhpFunctionContext {
    public var funcName: UnsafeMutablePointer<zend_string>
    public var retval: zval = zval()
    public var fci: zend_fcall_info = zend_fcall_info()
    public var fciCache: zend_fcall_info_cache = zend_fcall_info_cache()

    public init(functionName: String) {
        self.funcName = zend_string_init("", 0, false)
        self.fci.function_name.u1.type_info = 0
        self.fci.size = MemoryLayout<zend_fcall_info>.size
        self.fci.object = nil
        self.fci.retval = nil
        self.fci.param_count = 0
        self.fci.params = nil
        
        self.fciCache.function_handler = nil
        self.fciCache.calling_scope = nil
        self.fciCache.called_scope = nil
        self.fciCache.object = nil
        

        functionName.withCString { functionNameCS in
            let length = strlen(functionNameCS)
            if let funcName = zend_string_init(functionNameCS, length, false) {
                self.funcName = funcName
                ZVAL_STR(&self.fci.function_name, self.funcName)
            }
        }
    }

    public mutating func cleanup() {
        zend_string_release(self.funcName)
    }

    public mutating func reset() {
        // Release funcName if allocated
        zend_string_release(self.funcName)
        self.funcName = zend_string_init("", 0, false)

        // Release retval if it's been set or used
        if Z_TYPE(self.retval) != IS_UNDEF {
            zval_ptr_dtor(&self.retval)
            ZVAL_UNDEF(&self.retval)
        }

        // Clear zend_fcall_info
        self.fci.size = MemoryLayout<zend_fcall_info>.size
        self.fci.function_name.u1.type_info = 0
        self.fci.object = nil
        self.fci.retval = nil
        self.fci.param_count = 0
        self.fci.params = nil

        // Clear zend_fcall_info_cache
        self.fciCache.function_handler = nil
        self.fciCache.calling_scope = nil
        self.fciCache.called_scope = nil
        self.fciCache.object = nil
    }
}

#if ZTS_SWIFT
// ZTS (Thread Safe) version of the function
@_silgen_name("create_module_entry")
public func create_module_entry(
    _ name: UnsafePointer<CChar>?,
    _ version: UnsafePointer<CChar>?,
    _ functions: UnsafePointer<zend_function_entry>?,
    _ module_startup_func: @convention(c) (Int32, Int32) -> Int32,
    _ module_shutdown_func: @convention(c) (Int32, Int32) -> Int32,
    _ request_startup_func: @convention(c) (Int32, Int32) -> Int32,
    _ request_shutdown_func: @convention(c) (Int32, Int32) -> Int32,
    _ info_func: @convention(c) (UnsafeMutableRawPointer?) -> Void,
    _ globals_size: Int,
    _ globals_id_ptr: UnsafeMutablePointer<ts_rsrc_id>?, // Included for ZTS
    _ globals_ctor: @convention(c) (UnsafeMutableRawPointer?) -> Void,
    _ globals_dtor: @convention(c) (UnsafeMutableRawPointer?) -> Void,
    _ build_id: UnsafePointer<CChar>?
) -> UnsafeMutablePointer<zend_module_entry>
#else
// NTS (Non-Thread Safe) version of the function
@_silgen_name("create_module_entry")
public func create_module_entry(
    _ name: UnsafePointer<CChar>?,
    _ version: UnsafePointer<CChar>?,
    _ functions: UnsafePointer<zend_function_entry>?,
    _ module_startup_func: @convention(c) (Int32, Int32) -> Int32,
    _ module_shutdown_func: @convention(c) (Int32, Int32) -> Int32,
    _ request_startup_func: @convention(c) (Int32, Int32) -> Int32,
    _ request_shutdown_func: @convention(c) (Int32, Int32) -> Int32,
    _ info_func: @convention(c) (UnsafeMutableRawPointer?) -> Void,
    _ globals_size: Int,
    // globals_id_ptr is omitted for NTS
    _ globals_ctor: @convention(c) (UnsafeMutableRawPointer?) -> Void,
    _ globals_dtor: @convention(c) (UnsafeMutableRawPointer?) -> Void,
    _ build_id: UnsafePointer<CChar>?
) -> UnsafeMutablePointer<zend_module_entry>
#endif

public struct FunctionListBuilder {
    private var functions: [zend_function_entry] = []

    public init() {}

    // Original method for non-namespaced functions
    @discardableResult
    public mutating func add(
        name: String, 
        handler: ZifHandler?, 
        arg_info: [zend_internal_arg_info]?
    ) -> Self {
        // Assuming you have a ZEND_FENTRY or similar helper
        let entry = ZEND_FENTRY(zend_name: name, handler: handler, arg_info: arg_info, flags: 0)
        functions.append(entry)
        return self
    }

    // ✅ NEW: Overloaded method for namespaced functions
    @discardableResult
    public mutating func add(
        namespace: String, 
        name: String, 
        handler: ZifHandler?, 
        arg_info: [zend_internal_arg_info]?
    ) -> Self {
        // This method calls your new helper function
        let entry = ZEND_NS_FENTRY(
            ns: namespace, 
            zend_name: name, 
            handler: handler, 
            arg_info: arg_info, 
            flags: 0
        )
        functions.append(entry)
        return self
    }

    public func build() -> UnsafeMutablePointer<zend_function_entry> {
        var finalList = self.functions
        finalList.append(ZEND_FE_END())

        let pointer = UnsafeMutablePointer<zend_function_entry>.allocate(capacity: finalList.count)
        pointer.initialize(from: finalList, count: finalList.count)
        
        return pointer
    }
}


// @_silgen_name("std_object_handlers")
// var std_object_handlers: zend_object_handlers

// zend_get_std_object_handlers() \
// 	(&std_object_handlers)

// public func zend_get_std_object_handlers() -> UnsafePointer<zend_object_handlers> {
//     return UnsafePointer(&std_object_handlers)
// }

@_silgen_name("swift_zend_get_std_object_handlers")
func swift_zend_get_std_object_handlers() -> UnsafePointer<zend_object_handlers>!

public func zend_std_handlers_ptr_shim() -> UnsafePointer<zend_object_handlers> {
    swift_zend_get_std_object_handlers()
}