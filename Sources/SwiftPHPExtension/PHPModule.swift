import PHPCore
import Foundation

// Global pointers to hold data that will persist
@MainActor var raylib_functions_ptr: UnsafeMutablePointer<zend_function_entry>? = nil
@MainActor var raylib_ini_entries_ptr: UnsafeMutablePointer<zend_ini_entry>? = nil
@MainActor var raylib_deps_ptr: UnsafeMutablePointer<zend_module_dep>? = nil
@MainActor var raylibModule_ptr: UnsafeMutablePointer<zend_module_entry>? = nil 
#if ZTS
@MainActor var raylib_globals_id: ts_rsrc_id = 0
#endif

struct raylibGlobals {
    var someGlobalVariable: Int = 0
}


@_cdecl("zm_startup_raylib")
func zm_startup_raylib(type: Int32, module_number: Int32) -> Int32 {
    php_raylib_vector3_startup(type: type, module_number: module_number)
    return SUCCESS.rawValue
}

@_cdecl("zm_shutdown_raylib")
func zm_shutdown_raylib(type: Int32, module_number: Int32) -> Int32 {
    return Int32(SUCCESS.rawValue)
}

@_cdecl("zm_activate_raylib")
func zm_activate_raylib(type: Int32, module_number: Int32) -> Int32 {
    return Int32(SUCCESS.rawValue)
}

@_cdecl("zm_deactivate_raylib")
func zm_deactivate_raylib(type: Int32, module_number: Int32) -> Int32 {
    return Int32(SUCCESS.rawValue)
}

@_cdecl("zm_info_raylib")
func zm_info_raylib(zend_module: UnsafeMutableRawPointer?) {
    print("Raylib Module Version: 2.0.0")
}

@_cdecl("zm_globals_ctor_raylib")
func zm_globals_ctor_raylib(pointer: UnsafeMutableRawPointer?) {
    // let globals = pointer!.bindMemory(to: raylibGlobals.self, capacity: 1)
    // globals.pointee.someGlobalVariable = 42
}

@_cdecl("zm_globals_dtor_raylib")
func zm_globals_dtor_raylib(pointer: UnsafeMutableRawPointer?) {
    // Optional cleanup code for globals
}


@_cdecl("get_module")
@MainActor
func get_module() -> UnsafeMutablePointer<zend_module_entry> {
    // Allocate memory for raylib_functions
    var builder = FunctionListBuilder()
    functions_add_entries(builder: &builder)
    raylib_functions_ptr = builder.build()
    
    let version = strdup("2.0.0")
    let module_name = strdup("raylib")
    var buildIdString = "API\(PHP_API_VERSION)"

#if ZTS
    buildIdString += ",TS" // Thread Safe
#else
    buildIdString += ",NTS" // Non-Thread Safe
#endif

#if ZEND_DEBUG
    buildIdString += ",debug"
#endif

#if ZEND_WIN32
    buildIdString += ",VS17"
#endif

    let build_id = strdup(buildIdString)
    
    raylib_ini_entries_ptr = UnsafeMutablePointer<zend_ini_entry>.allocate(capacity: 1)
    raylib_ini_entries_ptr?.initialize(to: zend_ini_entry())
    
    raylib_deps_ptr = UnsafeMutablePointer<zend_module_dep>.allocate(capacity: 1)
    raylib_deps_ptr?.initialize(to: zend_module_dep())

#if ZTS
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

