+++
draft = false
title = 'PHP Extension Basics'
+++

# PHP Extension Basics

PHP has 4 configurations from source code to configuration. This means from the source code to the runtime, you have to compile your extension to match the following.

 - ZTS (Thread Safe) + Debug
 - ZTS (Thread Safe) + Release
 - NTS (Non-Thread Safe) + Debug
 - NTS (Non-Thread Safe) + Release

Do you need thread safety? PHP is ran a few different ways, if you are running this as a traditional web server setup, i.e Apache/Nginx and PHP-FPM then no you do not need thread safety. NTS (Non-thread safe) will run faster than ZTS since it wont have the thread context overhead. The times you'd want ZTS is when PHP is run inside, effectively embedded into the process and that process is multithreaded. Mod_PHP for Apache is a great example. 

If you are using Swift's concurrency you do not explicty need PHP's thread-safe version, its only when PHP itself is accessing data between its instances across thread. So in Swift you can use threads, as long as you return to the main thread for the response back to PHP. If you are embedding PHP yourself, then it will be safer to assume you need thread safety.


## Entry Point

All PHP extensions require `get_module` as the way to bootstrap your native PHP extesion. However with Swift, no function is directly C ABI compatible unless you annotate the function with `@_cdecl("get_module")`. This makes the functions ready to bootstrap your extension.

```swift
@_cdecl("get_module")
@MainActor
func get_module() -> UnsafeMutablePointer<zend_module_entry> {
    //....
}
```

## Startup & Shutdown Functions

Each extension has the ability to register shutdown and startup functions. They execute in this order:

 - globals_ctor
 - startup
 - activate
 - \<?php Execute PHP Script ?\>
 - deactivate
 - shutdown
 - globals_dtor

These are not required but allows you to work between instances of PHP runtimes (threads), or reject loading itself as an extension. You do need to annotate the functions with `@_cdecl` just like the entry point.

```swift

@_cdecl("zm_startup_raylib")
func zm_startup_raylib(type: Int32, module_number: Int32) -> Int32 {
    print("zm_startup_raylib")
    return Int32(SUCCESS.rawValue)
}

@_cdecl("zm_shutdown_raylib")
func zm_shutdown_raylib(type: Int32, module_number: Int32) -> Int32 {
    print("zm_shutdown_raylib")
    return Int32(SUCCESS.rawValue)
}

@_cdecl("zm_activate_raylib")
func zm_activate_raylib(type: Int32, module_number: Int32) -> Int32 {
    print("zm_activate_raylib")
    return Int32(SUCCESS.rawValue)
}

@_cdecl("zm_deactivate_raylib")
func zm_deactivate_raylib(type: Int32, module_number: Int32) -> Int32 {
    print("zm_deactivate_raylib")
    return Int32(SUCCESS.rawValue)
}

@_cdecl("zm_globals_ctor_raylib")
func zm_globals_ctor_raylib(pointer: UnsafeMutableRawPointer?) {
    print("zm_globals_ctor_raylib")
    let globals = pointer!.bindMemory(to: raylibGlobals.self, capacity: 1)
    globals.pointee.someGlobalVariable = 42
}

@_cdecl("zm_globals_dtor_raylib")
func zm_globals_dtor_raylib(pointer: UnsafeMutableRawPointer?) {
    print("zm_globals_dtor_raylib")
    // Optional cleanup code for globals
}
```

## Zend Module Entry

Inside your `get_module` you need to construct a `zend_module_entry` and return it. 

```swift
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
```

PHP, depending on how its going to be build has shifting structs and `zend_module_entry` is one of them where ZTS (thread-safe) extesions also need to register a `globals_id`. Here is the raw C struct declared in PHP-src:


```c
struct _zend_module_entry {
	unsigned short size;
	unsigned int zend_api;
	unsigned char zend_debug;
	unsigned char zts;
	const struct _zend_ini_entry *ini_entry;
	const struct _zend_module_dep *deps;
	const char *name;
	const struct _zend_function_entry *functions;
	zend_result (*module_startup_func)(INIT_FUNC_ARGS);
	zend_result (*module_shutdown_func)(SHUTDOWN_FUNC_ARGS);
	zend_result (*request_startup_func)(INIT_FUNC_ARGS);
	zend_result (*request_shutdown_func)(SHUTDOWN_FUNC_ARGS);
	void (*info_func)(ZEND_MODULE_INFO_FUNC_ARGS);
	const char *version;
	size_t globals_size;
#ifdef ZTS
	ts_rsrc_id* globals_id_ptr;
#else
	void* globals_ptr;
#endif
	void (*globals_ctor)(void *global);
	void (*globals_dtor)(void *global);
	zend_result (*post_deactivate_func)(void);
	int module_started;
	unsigned char type;
	void *handle;
	int module_number;
	const char *build_id;
};
```