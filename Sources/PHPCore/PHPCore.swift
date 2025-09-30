#if os(Linux) || os(Windows)
    @preconcurrency @_exported import CPHP
#else
    @preconcurrency @_exported import PHP
#endif

@_exported import CSwiftPHP

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
    _ globals_id_ptr: UnsafeMutablePointer<ts_rsrc_id>?,
    _ globals_ctor: @convention(c) (UnsafeMutableRawPointer?) -> Void,
    _ globals_dtor: @convention(c) (UnsafeMutableRawPointer?) -> Void,
    _ build_id: UnsafePointer<CChar>?
) -> UnsafeMutablePointer<zend_module_entry>

public struct FunctionListBuilder {
    private var functions: [zend_function_entry] = []

    public init() {}

    @discardableResult
    public mutating func add(name: String, handler: ZifHandler?, arg_info: [zend_internal_arg_info]?) -> Self {
        let entry = ZEND_FE(name: name, handler: handler, arg_info: arg_info)
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