import PHPCore
import Foundation

// @_silgen_name("swift_shutdown_concurrency")
// func swift_shutdown_concurrency()

// @_silgen_name("swift_task_asyncMainDrainQueue")
// internal func swift_task_asyncMainDrainQueue()

// @_silgen_name("swift_shutdown")
// internal func swift_shutdown()

// Global pointers to hold data that will persist
@MainActor var raylib_functions_ptr: UnsafeMutablePointer<zend_function_entry>? = nil
@MainActor var raylib_ini_entries_ptr: UnsafeMutablePointer<zend_ini_entry>? = nil
@MainActor var raylib_deps_ptr: UnsafeMutablePointer<zend_module_dep>? = nil
@MainActor var raylibModule_ptr: UnsafeMutablePointer<zend_module_entry>? = nil 
#if ZTS_SWIFT
@MainActor var raylib_globals_id: ts_rsrc_id = 0
#endif

struct raylibGlobals {
    var someGlobalVariable: Int = 0
}


@_cdecl("zm_startup_raylib")
func zm_startup_raylib(type: Int32, module_number: Int32) -> Int32 {
    print("[raylib] zm_startup_raylib called - type=\(type), module_number=\(module_number)")
    php_raylib_vector3_startup(type: type, module_number: module_number)
    defer {
        print("[raylib] zm_startup_raylib completed")
    }
    return SUCCESS.rawValue
}

@_cdecl("zm_shutdown_raylib")
func zm_shutdown_raylib(type: Int32, module_number: Int32) -> Int32 {
    print("[raylib] zm_shutdown_raylib called - type=\(type), module_number=\(module_number)")
    // perform any shutdown work here
    // swift_shutdown_concurrency()
    // swift_task_asyncMainDrainQueue()
    // swift_shutdown()
    defer {
        print("[raylib] zm_shutdown_raylib completed")
    }
    return Int32(SUCCESS.rawValue)
}

@_cdecl("zm_activate_raylib")
func zm_activate_raylib(type: Int32, module_number: Int32) -> Int32 {
    print("[raylib] zm_activate_raylib called - type=\(type), module_number=\(module_number)")
    print("[raylib] zm_activate_raylib completed")
    return Int32(SUCCESS.rawValue)
}

@_cdecl("zm_deactivate_raylib")
func zm_deactivate_raylib(type: Int32, module_number: Int32) -> Int32 {
    print("[raylib] zm_deactivate_raylib called - type=\(type), module_number=\(module_number)")
    print("[raylib] zm_deactivate_raylib completed")
    return Int32(SUCCESS.rawValue)
}

@_cdecl("zm_info_raylib")
func zm_info_raylib(zend_module: UnsafeMutableRawPointer?) {
    print("[raylib] zm_info_raylib called")
    print("Raylib Module Version: 2.0.0")
    print("[raylib] zm_info_raylib completed")
}

@_cdecl("zm_globals_ctor_raylib")
func zm_globals_ctor_raylib(pointer: UnsafeMutableRawPointer?) {
    print("[raylib] zm_globals_ctor_raylib called")
    if let p = pointer {
        let globals = p.bindMemory(to: raylibGlobals.self, capacity: 1)
        // initialize if needed
        globals.pointee.someGlobalVariable = globals.pointee.someGlobalVariable // noop to avoid warnings
        print("[raylib] zm_globals_ctor_raylib initialized globals.someGlobalVariable=\(globals.pointee.someGlobalVariable)")
    } else {
        print("[raylib] zm_globals_ctor_raylib received nil pointer")
    }
}

@_cdecl("zm_globals_dtor_raylib")
func zm_globals_dtor_raylib(pointer: UnsafeMutableRawPointer?) {
    print("[raylib] zm_globals_dtor_raylib called")
    if let p = pointer {
        // If any cleanup is necessary, do it here. For now, just log.
        print("[raylib] zm_globals_dtor_raylib pointer non-nil - cleanup (none)\n")
    } else {
        print("[raylib] zm_globals_dtor_raylib received nil pointer")
    }
}


@_cdecl("get_module")
@MainActor
func get_module() -> UnsafeMutablePointer<zend_module_entry> {
    // Allocate memory for raylib_functions
    var builder = FunctionListBuilder()
    functions_add_entries(builder: &builder)
    vector3_functions_add_entries(builder: &builder)
    // spritekit_add_entries(builder: &builder)
    raylib_functions_ptr = builder.build()
    
    let version = strdup("2.0.0")
    let module_name = strdup("raylib")

    let build_id = strdup(ZEND_MODULE_BUILD_ID)
    
    raylib_ini_entries_ptr = UnsafeMutablePointer<zend_ini_entry>.allocate(capacity: 1)
    raylib_ini_entries_ptr?.initialize(to: zend_ini_entry())
    
    raylib_deps_ptr = UnsafeMutablePointer<zend_module_dep>.allocate(capacity: 1)
    raylib_deps_ptr?.initialize(to: zend_module_dep())

#if ZTS_SWIFT
    raylibModule_ptr = create_module_entry(
        module_name,
        version,
        raylib_functions_ptr,
        zm_startup_raylib,
        zm_shutdown_raylib,
        zm_activate_raylib,
        zm_deactivate_raylib,
        zm_info_raylib,
        MemoryLayout<raylibGlobals>.size,
        &raylib_globals_id,
        zm_globals_ctor_raylib,
        zm_globals_dtor_raylib,
        build_id
    )
#else
    raylibModule_ptr = create_module_entry(
        module_name,
        version,
        raylib_functions_ptr,
        zm_startup_raylib,
        zm_shutdown_raylib,
        zm_activate_raylib,
        zm_deactivate_raylib,
        zm_info_raylib,
        MemoryLayout<raylibGlobals>.size,
        zm_globals_ctor_raylib,
        zm_globals_dtor_raylib,
        build_id
    )
#endif
    
    return raylibModule_ptr!
}

