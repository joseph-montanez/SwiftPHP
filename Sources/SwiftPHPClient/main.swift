import SwiftPHP
import Foundation

@freestanding(expression)
macro staticCString(_ str: StaticString) -> (UnsafePointer<CChar>, Int) = #externalMacro(module: "SwiftPHPMacros", type: "StaticCStringMacro")

// func iniDefault(_ name: String, _ value: String, configurationHash: UnsafeMutablePointer<HashTable>) {
//     var tmp = zval()
    
//     // Create zend_string for the value
//     value.withCString { cValue in
//         let zendStr = zend_string_init(cValue, strlen(cValue), true)
//         ZVAL_NEW_STR(&tmp, zendStr!)
//     }
    
//     // Update the configuration hash table with the name and value
//     name.withCString { cName in
//         zend_hash_str_update(configurationHash, cName, strlen(cName), &tmp)
//     }
    
//     // Optionally clean up (depending on your needs)
//     // zval_ptr_dtor(&tmp)
// }

// let set_ini_defaults: @convention(c) (UnsafeMutablePointer<HashTable>?) -> Void = { ini_defaults in
    // iniDefault("memory_limit", "1024M", configurationHash: ini_defaults!)
    // iniDefault("display_errors", "on", configurationHash: ini_defaults!)

    // var memoryLimitValue:UnsafeMutablePointer<zend_string>? = nil
    // memoryLimitValue = zend_string_init(*ini, strlen( *ini ), 1);
    // if let key = "memory_limit", let value = "-1" {
    //     key.withCString { cKey in
    //         psKey = zend_string_init(cKey, strlen(cKey), 1)
    //     }

    //     value.withCString { cValue in
    //         zend_hash_str_update(ini_defaults, UnsafeMutablePointer(mutating: cValue), strlen(cValue), &iniValue)
    //         zend_alter_ini_entry_chars(psKey, UnsafeMutablePointer(mutating: cValue), strlen(cValue), PHP_INI_SYSTEM, PHP_INI_STAGE_ACTIVATE)
    //     }


    //     zend_string_release_ex(psKey, 1)
    // }
    // ZVAL_STRINGL(&memoryLimitValue, "1024", 4)
    // zend_hash_str_update(ini_defaults, "memory_limit", 12, &memoryLimitValue)
    // zval_ptr_dtor(&memoryLimitValue)

    // var iniValue = zval()
    // if let zendString = zend_string_init("-1", strlen("-1"), true) {
    //     ZEND_STRL("memory_limit") { cStr, length in
    //         ZVAL_NEW_STR(&iniValue, zendString)
    //         zend_hash_str_update(ini_defaults, cStr, length, &iniValue)
    //     }
    //     zend_string_release(zendString)
    // }


    // var displayErrorsValue = zval()
    // ZVAL_STRINGL(&displayErrorsValue, "on", 2)
    // zend_hash_str_update(ini_defaults, "display_errors", 14, &displayErrorsValue)
    // zval_ptr_dtor(&displayErrorsValue)

    // var errorReportingValue = zval()
    // ZVAL_STRINGL(&errorReportingValue, "E_ALL", 5)
    // zend_hash_str_update(ini_defaults, "error_reporting", 15, &errorReportingValue)
    // zval_ptr_dtor(&errorReportingValue)
// }

// let phrost_error: @convention(c) (Int32, UnsafeMutablePointer<zend_string>?, UInt32, UnsafeMutablePointer<zend_string>?) -> Void = { type, error_filename, error_lineno, message in
//     let filename = error_filename != nil ? String(cString: ZSTR_VAL(error_filename!)) : "Unknown"
//     let msg = message != nil ? String(cString: ZSTR_VAL(message!)) : "Unknown error"

//     print("Error [\(type)] at \(filename):\(error_lineno): \(msg)")
// }

let phrost_log_message: @convention(c) (UnsafePointer<CChar>?, Int32) -> Void = { message, syslog_type_int in
    guard let message = message else {
        print("[ERROR] Null message received")
        return
    }

    let swiftMessage = String(cString: message)
    var logLevel: String

    switch syslog_type_int {
    case LOG_ERR:
        logLevel = "ERROR"
    case LOG_WARNING:
        logLevel = "WARNING"
    case LOG_INFO:
        logLevel = "INFO"
    default:
        logLevel = "VERBOSE"
    }

    print("[\(logLevel)] \(swiftMessage)")
}




func loadScript() -> (Bool, String) {
    var retval = false;
    var file_handle: zend_file_handle = zend_file_handle();
    var ret: ZEND_RESULT_CODE;

    if let filename = Phrost_GetAssetPath(assetName: "assets/main", ofType: "php") {
        zend_stream_init_filename(&file_handle, filename)
        
        ret = php_stream_open_for_zend_ex(&file_handle, USE_PATH | REPORT_ERRORS | STREAM_OPEN_FOR_INCLUDE)

        if (ret == SUCCESS) {
            print("Opened file stream")
            retval = php_execute_script(&file_handle)
            zend_destroy_file_handle(&file_handle)

            if (retval) {
                print("File was loaded")
                let filenameStr = String(cString: filename)
                // Free filename if allocated
                free(UnsafeMutableRawPointer(mutating: filename))  // Ensure to free memory if dynamically allocated
                return (true, filenameStr)
            } else {
                print("Error: Script execution failed without throwing an exception")
            }
        }

        // Free filename in case of failure
        free(UnsafeMutableRawPointer(mutating: filename))
    }


    return (false, String(""))
}

// func reloadScript(_ filename: String) -> Bool {
//     var retval = false;
//     var file_handle: zend_file_handle = zend_file_handle();
//     var ret: ZEND_RESULT_CODE;

//     zend_stream_init_filename(&file_handle, filename.cString(using: .utf8));

//     ret = php_stream_open_for_zend_ex(&file_handle, USE_PATH|REPORT_ERRORS|STREAM_OPEN_FOR_INCLUDE);

//     if (ret == SUCCESS) {
//         print("Reloading \(filename)...")
//         retval = safe_php_execute_script(&file_handle);
//         zend_destroy_file_handle(&file_handle);

//         if (retval) {
//             print("File was loaded")
            
//             return true
//         } else {
//             print("Reload Error: Script execution failed without throwing an exception")
//         }

//         return true
//     } else {
//         print("Failed to reload script \(filename)")
//     }

//     return false
// }

func runCommand(_ command: String) -> String {
    let process = Process()
    let pipe = Pipe()

    process.standardOutput = pipe
    process.standardError = pipe
    process.arguments = ["-c", command]
    process.executableURL = URL(fileURLWithPath: "/bin/bash")
    
    do {
        try process.run()
    } catch {
        return ""
    }

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8) ?? ""
}

// Event struct to define the type of event to pass between tasks
struct Event: Sendable{
    let message: String
}

// Define an event emitter using AsyncStream
class EventEmitter: @unchecked Sendable {
    private var continuation: AsyncStream<Event>.Continuation?

    func emit(event: Event) {
        continuation?.yield(event)
    }

    func eventStream() -> AsyncStream<Event> {
        return AsyncStream { continuation in
            self.continuation = continuation
        }
    }
}

// Global event emitter instance
let eventEmitter = EventEmitter()


// C-style callback function
let swiftCallback: @convention(c) () -> Void = {
    var phrostUpdateFn = PhpFunctionContext(functionName: "phrost_update")
    var phrostSleepFn = PhpFunctionContext(functionName: "phrost_sleep")
    var phrostWakeFn = PhpFunctionContext(functionName: "phrost_wake")

    let (loaded, fileName) = loadScript()

    if loaded {
        let done = false
        var reload = false

        Task.detached {
            for await event in eventEmitter.eventStream() {
                print("Received event: \(event.message)")
                // reload = true
                break
            }
        }

        while !done {
            print("Calling function...")

            if (reload) {
                // do reloady stuff
                print("Reloading due to event.")
                usleep(250_00)

                // Cleanup
                print("Cleaning up for reload...")
                // phrostUpdateFn.cleanup()
                // phrostSleepFn.cleanup()
                // phrostWakeFn.cleanup()
                // php_embed_shutdown()

                break

                // let argc = Int32(CommandLine.argc)
                // let argv = CommandLine.unsafeArgv

                // let embedModule: UnsafeMutablePointer<sapi_module_struct> = get_php_embed_module()
                // embedModule.pointee.ini_defaults = set_ini_defaults
                // embedModule.pointee.error_function = phrost_error
                // embedModule.pointee.log_message = phrost_log_message


                // print("Reload: PHP embed init")
                // php_embed_init(argc, argv)

                // //-- Load up main.php
                // print("Loading PHP main file...")

                // let reloaded = reloadScript(fileName)

                // if (reloaded) {
                //     print("File was reloaded")
                //     phrostUpdateFn = PhpFunctionContext(functionName: "phrost_update")
                //     reload = false
                // } else {
                //     print("Failed to reload")
                // }
            }

            executeFunction(context: &phrostUpdateFn, eventsArray: nil)
            // sleep(1)

            reload = true
        }

        phrostUpdateFn.cleanup()
        phrostSleepFn.cleanup()
        phrostWakeFn.cleanup()
    } else {
        print("Failed to load \(fileName), maybe the file is missing?")
    }
}

final class Atomic<T: Sendable>: @unchecked Sendable {
    private let queue = DispatchQueue(label: "atomic-queue", attributes: .concurrent)
    private var value: T

    init(_ value: T) {
        self.value = value
    }

    func read() -> T {
        return queue.sync { value }
    }

    func write(_ newValue: T) {
        queue.async(flags: .barrier) { [newValue] in
            self.value = newValue
        }
    }
}

func watchFolder(path: String, interval: TimeInterval) {
    let previousResult = Atomic(runCommand("ls -laR \(path)"))

    Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
        let currentResult = runCommand("ls -laR \(path)")
        if previousResult.read() != currentResult {
            previousResult.write(currentResult)
            Task {
                eventEmitter.emit(event: Event(message: "Reload triggered from folder watch"))
            }
        }
    }

    RunLoop.current.run()
}

func main() {

    Task.detached {
        while true {
            let argc = Int32(CommandLine.argc)
            let argv = CommandLine.unsafeArgv

            print("PHP configuration")
            // let embedModule: UnsafeMutablePointer<sapi_module_struct> = get_php_embed_module()
            // await embedModule.pointee.ini_defaults = set_ini_defaults
            // await embedModule.pointee.log_message = phrost_log_message

            print("PHP embed init")
            php_embed_init(argc, argv)

            //-- Load up main.php
            print("Loading PHP main file...")

            _ = await call_php_with_try(swiftCallback) // Execute the callback inside the thread

            // Cleanup
            print("Cleaning up...")
            php_embed_shutdown()

            print("Shutdown complete.")

            sleep(5)
        }
    }


    // Folder watch task
    Task.detached {
        watchFolder(path: "assets", interval: 1.0)
    }

    while true {
        usleep(500_000)
    }
}

func executeFunction(context: inout PhpFunctionContext, eventsArray: UnsafeMutablePointer<zval>?) {
    var dt_val = zval()
    ZVAL_DOUBLE(&dt_val, 10.0)

    // Create a params array to hold zval values
    var params: [zval] = []

    // Check if eventsArray is provided
    if let eventsArray = eventsArray {
        // If eventsArray is not nil, add both dt_val and eventsArray to params
        params.append(dt_val)
        params.append(eventsArray.pointee)

        // Set param count to 2
        context.fci.param_count = 2
    } else {
        // If eventsArray is nil, only add dt_val
        params.append(dt_val)

        // Set param count to 1
        context.fci.param_count = 1
    }

    // Set the params pointer, size, and return value for the function call
    context.fci.params = params.withUnsafeBufferPointer { 
        UnsafeMutablePointer(mutating: $0.baseAddress) 
    }    
    context.fci.size = MemoryLayout.size(ofValue: context.fci)
    context.fci.retval = withUnsafeMutablePointer(to: &context.retval) { $0 }

    // Call the function using the env's fci and fci_cache
    let fnResult = zend_call_function(&context.fci, &context.fciCache)
    if (fnResult == SUCCESS) {
        print("")
    } else {
        print("Unknown error occurred during function call");
    }

    if (fnResult == SUCCESS && Z_TYPE(context.retval) != IS_UNDEF) {
        zval_ptr_dtor(&context.retval);
    }
}

main()