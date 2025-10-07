@preconcurrency import PHPCore
import CSwiftPHP
import Foundation

@_silgen_name("swift_zend_get_std_object_handlers")
func swift_zend_get_std_object_handlers() -> UnsafePointer<zend_object_handlers>!

public func zend_std_handlers_ptr_shim() -> UnsafePointer<zend_object_handlers> {
    swift_zend_get_std_object_handlers()
}

@frozen
public struct Vector3 { public var x: Double; public var y: Double; public var z: Double }

@frozen
public struct php_raylib_vector3_object {
    public var vector3: Vector3
    public var prop_handler: UnsafeMutablePointer<HashTable>?
    public var std: zend_object
}

@inline(__always) func asObject(_ p: UnsafeMutableRawPointer?) -> UnsafeMutablePointer<php_raylib_vector3_object> { p!.assumingMemoryBound(to: php_raylib_vector3_object.self) }
@inline(__always) func asZval(_ p: UnsafeMutableRawPointer?) -> UnsafeMutablePointer<zval> { p!.assumingMemoryBound(to: zval.self) }
@inline(__always) func fetchObject(_ obj: UnsafeMutablePointer<zend_object>?) -> UnsafeMutablePointer<php_raylib_vector3_object> {
    let offset = MemoryLayout.offset(of: \php_raylib_vector3_object.std)!
    let base = UnsafeMutableRawPointer(obj!).advanced(by: -offset)
    return base.assumingMemoryBound(to: php_raylib_vector3_object.self)
}

//-- PHP Class Properties are separated by its type and then readers and writers
// Since this object only has floats as its properties, it only needs float reader and writer.
public typealias raylib_vector3_read_float_t = @convention(c) (_ obj: UnsafeMutableRawPointer?, _ retval: UnsafeMutableRawPointer?) -> CInt
public typealias raylib_vector3_write_float_t = @convention(c) (_ obj: UnsafeMutableRawPointer?, _ value: UnsafeMutableRawPointer?) -> CInt

// We then wrap all the readers and writers into handler that the object will hold onto for quick lookup.
@frozen
public struct raylib_vector3_prop_handler {
    public var read_float_func: raylib_vector3_read_float_t?
    public var write_float_func: raylib_vector3_write_float_t?
}

//-- The object's PHP state then is wrapped in a class to bypass concurrency compiler issue.
final class V3State: @unchecked Sendable {
    static let shared = V3State()
    let handlersPtr: UnsafeMutablePointer<zend_object_handlers>
    let propHandlersPtr: UnsafeMutablePointer<HashTable>
    let methodsPtr: UnsafeMutablePointer<zend_function_entry>
    var ce: UnsafeMutablePointer<zend_class_entry>?
    private init() {
        handlersPtr = .allocate(capacity: 1); handlersPtr.initialize(to: zend_object_handlers())
        propHandlersPtr = .allocate(capacity: 1); propHandlersPtr.initialize(to: HashTable())
        methodsPtr = .allocate(capacity: 2)
        ce = nil
    }
}

//-- The reader property function will filter between the types of the properties and then call the correct reader for each type.
// since this class only has one type, there is no need for a check and just calls the float reader
public func php_raylib_vector3_property_reader(_ obj: UnsafeMutablePointer<php_raylib_vector3_object>?, _ hnd: UnsafePointer<raylib_vector3_prop_handler>?, _ rv: UnsafeMutablePointer<zval>?) -> UnsafeMutablePointer<zval>? {
    guard let hnd = hnd, let fn = hnd.pointee.read_float_func else { return rv }
    _ = fn(UnsafeMutableRawPointer(obj), UnsafeMutableRawPointer(rv))
    return rv
}

@_cdecl("php_raylib_vector3_get_property_ptr_ptr")
public func php_raylib_vector3_get_property_ptr_ptr(_ object: UnsafeMutablePointer<zend_object>?, _ name: UnsafeMutablePointer<zend_string>?, _ prop_type: CInt, _ cache_slot: UnsafeMutablePointer<UnsafeMutableRawPointer?>?) -> UnsafeMutablePointer<zval>? {
    let intern = fetchObject(object)
    if let table = intern.pointee.prop_handler, zend_hash_find_ptr(table, name) != nil {
        cache_slot?.pointee = nil
        return nil
    }
    return zend_std_get_property_ptr_ptr(object, name, prop_type, cache_slot)
}

@_cdecl("php_raylib_vector3_read_property")
public func php_raylib_vector3_read_property(_ object: UnsafeMutablePointer<zend_object>?, _ name: UnsafeMutablePointer<zend_string>?, _ prop_type: CInt, _ cache_slot: UnsafeMutablePointer<UnsafeMutableRawPointer?>?, _ rv: UnsafeMutablePointer<zval>?) -> UnsafeMutablePointer<zval>? {
    let intern = fetchObject(object)
    var hnd: UnsafeMutablePointer<raylib_vector3_prop_handler>? = nil
    if let table = intern.pointee.prop_handler, let raw = zend_hash_find_ptr(table, name) { hnd = raw.assumingMemoryBound(to: raylib_vector3_prop_handler.self) }
    if let h = hnd { return php_raylib_vector3_property_reader(intern, UnsafePointer(h), rv) }
    return zend_std_read_property(object, name, prop_type, cache_slot, rv)
}

@_cdecl("php_raylib_vector3_write_property")
public func php_raylib_vector3_write_property(_ object: UnsafeMutablePointer<zend_object>?, _ member: UnsafeMutablePointer<zend_string>?, _ value: UnsafeMutablePointer<zval>?, _ cache_slot: UnsafeMutablePointer<UnsafeMutableRawPointer?>?) -> UnsafeMutablePointer<zval>? {
    let intern = fetchObject(object)
    var hnd: UnsafeMutablePointer<raylib_vector3_prop_handler>? = nil
    if let table = intern.pointee.prop_handler, let raw = zend_hash_find_ptr(table, member) { hnd = raw.assumingMemoryBound(to: raylib_vector3_prop_handler.self) }
    if let h = hnd, let writer = h.pointee.write_float_func { _ = writer(UnsafeMutableRawPointer(intern), UnsafeMutableRawPointer(value)); return value }
    return zend_std_write_property(object, member, value, cache_slot)
}

@_cdecl("php_raylib_vector3_has_property")
public func php_raylib_vector3_has_property(_ object: UnsafeMutablePointer<zend_object>?, _ name: UnsafeMutablePointer<zend_string>?, _ has_set_exists: CInt, _ cache_slot: UnsafeMutablePointer<UnsafeMutableRawPointer?>?) -> CInt {
    let intern = fetchObject(object)
    var hnd: UnsafeMutablePointer<raylib_vector3_prop_handler>? = nil
    if let table = intern.pointee.prop_handler, let raw = zend_hash_find_ptr(table, name) { hnd = raw.assumingMemoryBound(to: raylib_vector3_prop_handler.self) }
    if hnd != nil {
        switch has_set_exists {
        case CInt(ZEND_PROPERTY_EXISTS): return 1
        case CInt(ZEND_PROPERTY_NOT_EMPTY):
            var tmp = zval()
            if let v = php_raylib_vector3_read_property(object, name, BP_VAR_IS, cache_slot, &tmp) {
                let isNull = (Z_TYPE_P(v) == IS_NULL); let ret: CInt = isNull ? 0 : 1; zval_ptr_dtor(v); return ret
            }
            return 0
        case CInt(ZEND_PROPERTY_ISSET):
            var tmp = zval()
            if let v = php_raylib_vector3_read_property(object, name, BP_VAR_IS, cache_slot, &tmp) {
                let ret: CInt = (Z_TYPE_P(v) != IS_NULL) ? 1 : 0; zval_ptr_dtor(v); return ret
            }
            return 0
        default: return 0
        }
    }
    return zend_std_has_property(object, name, has_set_exists, cache_slot)
}

@_cdecl("php_raylib_vector3_get_gc")
public func php_raylib_vector3_get_gc(_ object: UnsafeMutablePointer<zend_object>?, _ gc_data: UnsafeMutablePointer<UnsafeMutablePointer<zval>?>?, _ gc_data_count: UnsafeMutablePointer<CInt>?) -> UnsafeMutablePointer<HashTable>? {
    gc_data?.pointee = nil; gc_data_count?.pointee = 0; return zend_std_get_properties(object)
}


@_cdecl("php_raylib_vector3_get_properties")
public func php_raylib_vector3_get_properties(_ object: UnsafeMutablePointer<zend_object>?) -> UnsafeMutablePointer<HashTable>? {
    let intern = fetchObject(object); let props = zend_std_get_properties(object)
    var handlerPtr: UnsafeMutablePointer<raylib_vector3_prop_handler>? = nil
    let ctx = Unmanaged.passRetained(PropsIter(obj: intern, props: props!, hnd: handlerPtr)).toOpaque()
    guard let prop_handler: UnsafeMutablePointer<HashTable> = intern.pointee.prop_handler else { return props }
    ZEND_HASH_FOREACH_STR_KEY_PTR(prop_handler) { key, ptr in
        let this = Unmanaged<PropsIter>.fromOpaque(ctx).takeUnretainedValue()
        var rv = zval()
        if let ptr = ptr { this.hnd = ptr.assumingMemoryBound(to: raylib_vector3_prop_handler.self) }
        if let h = this.hnd {
            _ = php_raylib_vector3_property_reader(this.obj, UnsafePointer(h), &rv)
            _ = zend_hash_update(this.props, key, &rv)
        }
    }
    Unmanaged<PropsIter>.fromOpaque(ctx).release(); return props
}

final class PropsIter {
    var obj: UnsafeMutablePointer<php_raylib_vector3_object>
    var props: UnsafeMutablePointer<HashTable>
    var hnd: UnsafeMutablePointer<raylib_vector3_prop_handler>?
    init(obj: UnsafeMutablePointer<php_raylib_vector3_object>, props: UnsafeMutablePointer<HashTable>, hnd: UnsafeMutablePointer<raylib_vector3_prop_handler>?) { self.obj = obj; self.props = props; self.hnd = hnd }
}

@_cdecl("php_raylib_vector3_free_prop_handler")
public func php_raylib_vector3_free_prop_handler(_ el: UnsafeMutablePointer<zval>?) {}

public func php_raylib_vector3_register_prop_handler(_ prop_handler: UnsafeMutablePointer<HashTable>?, _ name: UnsafePointer<CChar>, _ read_float_func: raylib_vector3_read_float_t?, _ write_float_func: raylib_vector3_write_float_t?) {
    var hnd = raylib_vector3_prop_handler(read_float_func: read_float_func, write_float_func: write_float_func)
    withUnsafeMutablePointer(to: &hnd) { p in
        let rawPtr = UnsafeMutableRawPointer(p)
        _ = zend_hash_str_add_mem(prop_handler, name, strlen(name), rawPtr, MemoryLayout<raylib_vector3_prop_handler>.size)
    }
    zend_declare_property_null(V3State.shared.ce, name, strlen(name), ZEND_ACC_PUBLIC)
}

@_cdecl("php_raylib_vector3_get_x")
public func php_raylib_vector3_get_x(_ obj: UnsafeMutableRawPointer?, _ retval: UnsafeMutableRawPointer?) -> CInt { let v = asObject(obj); let zv = asZval(retval); ZVAL_DOUBLE(zv, CDouble(v.pointee.vector3.x)); return SUCCESS.rawValue }
@_cdecl("php_raylib_vector3_get_y")
public func php_raylib_vector3_get_y(_ obj: UnsafeMutableRawPointer?, _ retval: UnsafeMutableRawPointer?) -> CInt { let v = asObject(obj); let zv = asZval(retval); ZVAL_DOUBLE(zv, CDouble(v.pointee.vector3.y)); return SUCCESS.rawValue }
@_cdecl("php_raylib_vector3_get_z")
public func php_raylib_vector3_get_z(_ obj: UnsafeMutableRawPointer?, _ retval: UnsafeMutableRawPointer?) -> CInt { let v = asObject(obj); let zv = asZval(retval); ZVAL_DOUBLE(zv, CDouble(v.pointee.vector3.z)); return SUCCESS.rawValue }
@_cdecl("php_raylib_vector3_set_x")
public func php_raylib_vector3_set_x(_ obj: UnsafeMutableRawPointer?, _ newval: UnsafeMutableRawPointer?) -> CInt { let v = asObject(obj); let isNull = (Z_TYPE_P(asZval(newval)) == IS_NULL); v.pointee.vector3.x = isNull ? 0.0 : Double(Z_DVAL_P(asZval(newval))); return SUCCESS.rawValue }
@_cdecl("php_raylib_vector3_set_y")
public func php_raylib_vector3_set_y(_ obj: UnsafeMutableRawPointer?, _ newval: UnsafeMutableRawPointer?) -> CInt { let v = asObject(obj); let isNull = (Z_TYPE_P(asZval(newval)) == IS_NULL); v.pointee.vector3.y = isNull ? 0.0 : Double(Z_DVAL_P(asZval(newval))); return SUCCESS.rawValue }
@_cdecl("php_raylib_vector3_set_z")
public func php_raylib_vector3_set_z(_ obj: UnsafeMutableRawPointer?, _ newval: UnsafeMutableRawPointer?) -> CInt { let v = asObject(obj); let isNull = (Z_TYPE_P(asZval(newval)) == IS_NULL); v.pointee.vector3.z = isNull ? 0.0 : Double(Z_DVAL_P(asZval(newval))); return SUCCESS.rawValue }

@_cdecl("php_raylib_vector3_free_storage")
public func php_raylib_vector3_free_storage(_ obj: UnsafeMutablePointer<zend_object>?) {
    guard let obj = obj else { return }
    let off = Int(V3State.shared.handlersPtr.pointee.offset)
    let intern = UnsafeMutableRawPointer(obj).advanced(by: -off).assumingMemoryBound(to: php_raylib_vector3_object.self)
    zend_object_std_dtor(&intern.pointee.std)
}

@preconcurrency
func php_raylib_vector3_object_creation_impl(_ ce: UnsafeMutablePointer<zend_class_entry>?, _ orig: UnsafeMutablePointer<zend_object>?) -> UnsafeMutablePointer<zend_object>? {
    guard let ce = ce else { return nil }
    guard let raw = zend_object_alloc(MemoryLayout<php_raylib_vector3_object>.size, ce) else { return nil }
    let intern = raw.assumingMemoryBound(to: php_raylib_vector3_object.self)
    if let orig = orig { let other = fetchObject(orig); intern.pointee.vector3 = other.pointee.vector3 } else { intern.pointee.vector3 = Vector3(x: 0, y: 0, z: 0) }
    zend_object_std_init(&intern.pointee.std, ce)
    object_properties_init(&intern.pointee.std, ce)
    intern.pointee.prop_handler = V3State.shared.propHandlersPtr
    intern.pointee.std.handlers = UnsafePointer(V3State.shared.handlersPtr)
    let stdOff = MemoryLayout<php_raylib_vector3_object>.offset(of: \.std)!
    let stdPtr = raw.advanced(by: stdOff).assumingMemoryBound(to: zend_object.self)
    return stdPtr
}

@preconcurrency @_cdecl("php_raylib_vector3_new_ex")
public func php_raylib_vector3_new_ex(_ ce: UnsafeMutablePointer<zend_class_entry>?, _ orig: UnsafeMutablePointer<zend_object>?) -> UnsafeMutablePointer<zend_object>? {
    php_raylib_vector3_object_creation_impl(ce, orig)
}

@_cdecl("php_raylib_vector3_new")
public func php_raylib_vector3_new(_ ce: UnsafeMutablePointer<zend_class_entry>?) -> UnsafeMutablePointer<zend_object>? {
    guard let ce = ce else { return nil }
    guard let raw = zend_object_alloc(MemoryLayout<php_raylib_vector3_object>.size, ce) else { return nil }
    let intern = raw.assumingMemoryBound(to: php_raylib_vector3_object.self)
    intern.pointee.vector3 = Vector3(x: 0, y: 0, z: 0)
    zend_object_std_init(&intern.pointee.std, ce)
    object_properties_init(&intern.pointee.std, ce)
    intern.pointee.prop_handler = V3State.shared.propHandlersPtr
    intern.pointee.std.handlers = UnsafePointer(V3State.shared.handlersPtr)
    let stdOff = MemoryLayout<php_raylib_vector3_object>.offset(of: \.std)!
    let stdPtr = raw.advanced(by: stdOff).assumingMemoryBound(to: zend_object.self)
    return stdPtr
}

@preconcurrency @_cdecl("php_raylib_vector3_clone")
public func php_raylib_vector3_clone(_ old_object: UnsafeMutablePointer<zend_object>?) -> UnsafeMutablePointer<zend_object>? {
    guard let old_object else { return nil }
    let new_object = php_raylib_vector3_object_creation_impl(old_object.pointee.ce, old_object)
    if let new_object = new_object { zend_objects_clone_members(new_object, old_object) }
    return new_object
}

@preconcurrency
let arginfo_vector3__construct = [
    ZEND_BEGIN_ARG_INFO_EX(name: "__construct", return_reference: false, required_num_args: 0),
    ZEND_ARG_TYPE_MASK(passByRef: false, name: "x", typeMask: UInt32(MAY_BE_DOUBLE|MAY_BE_NULL), defaultValue: "0"),
    ZEND_ARG_TYPE_MASK(passByRef: false, name: "y", typeMask: UInt32(MAY_BE_DOUBLE|MAY_BE_NULL), defaultValue: "0"),
    ZEND_ARG_TYPE_MASK(passByRef: false, name: "z", typeMask: UInt32(MAY_BE_DOUBLE|MAY_BE_NULL), defaultValue: "0"),
]

@MainActor
public let arginfo_vector3_sum: [zend_internal_arg_info] = [
    ZEND_BEGIN_ARG_INFO_EX(name: "vector3_sum", return_reference: false, required_num_args: 1),
    ZEND_ARG_INFO(pass_by_ref: false, name: "vectors")
]
@_cdecl("zif_vector3_sum")
public func zif_arginfo_vector3_sum(
    _ execute_data: UnsafeMutablePointer<zend_execute_data>?, 
    _ return_value: UnsafeMutablePointer<zval>?
) {
    var vectorsParam: UnsafeMutablePointer<zval>? = nil

    guard let return_value = return_value else {
        return
    }

    do {
        guard var state = ZEND_PARSE_PARAMETERS_START(min: 1, max: 1, execute_data: execute_data) else { return }
        try Z_PARAM_ARRAY(state: &state, dest: &vectorsParam)
        try ZEND_PARSE_PARAMETERS_END(state: state)
    } catch { return }

    guard let vectors = vectorsParam else { return }

    let vector_hash = Z_ARRVAL_P(vectors)
    var total = Vector3(x: 0, y: 0, z: 0)


    // Ensure the class entry has been initialised
    guard let vector3_ce = V3State.shared.ce else {
        // zend_error(Int32(E_WARNING), "Vector3 class is not initialised")
        return
    }

    ZEND_HASH_FOREACH_VAL(vector_hash) { vectorZval in
        guard Z_TYPE_P(vectorZval) == IS_OBJECT else {
            // zend_error(Int32(E_WARNING), "An element in the array is not an object")
            return // Skip non-object elements
        }

        guard Z_OBJCE_P(vectorZval) == vector3_ce else {
            // zend_error(Int32(E_WARNING), "An object in the array is not of type raylib\\Vector3")
            return // Skip elements that are not Vector3 objects
        }

        let obj = Z_OBJ_P(vectorZval)
        let intern = fetchObject(obj)

        total.x += intern.pointee.vector3.x
        total.y += intern.pointee.vector3.y
        total.z += intern.pointee.vector3.z
    }

    var resultObj = zval()
    _ = object_init_ex(&resultObj, vector3_ce)
    let resultIntern: UnsafeMutablePointer<php_raylib_vector3_object> = fetchObject(Z_OBJ_P(&resultObj))
    resultIntern.pointee.vector3 = total
    
    RETURN_OBJ(return_value, Z_OBJ_P(&resultObj))
}

final class ResultBox<T>: @unchecked Sendable {
    private var value: T?
    private let lock = NSLock()

    func set(_ value: T) {
        lock.lock()
        defer { lock.unlock() }
        self.value = value
    }

    func get() -> T? {
        lock.lock()
        defer { lock.unlock() }
        return self.value
    }
}

func calculateTotalPairwiseDistanceParallel(vectors nativeVectors: [Vector3]) async -> Double {
    let count = nativeVectors.count
    guard count >= 2 else { return 0.0 }

    // let processorCount = ProcessInfo.processInfo.activeProcessorCount
    let processorCount = 1
    let chunkSize = (count + processorCount - 1) / processorCount

    return await withTaskGroup(of: Double.self, returning: Double.self) { group in

        for i in stride(from: 0, to: count, by: chunkSize) {
            let end = min(i + chunkSize, count)
            let chunkRange = i..<end

            group.addTask {
                var localTotal: Double = 0.0

                for i_inner in chunkRange {
                    for j in (i_inner + 1)..<count {
                        let dx = nativeVectors[i_inner].x - nativeVectors[j].x
                        let dy = nativeVectors[i_inner].y - nativeVectors[j].y
                        let dz = nativeVectors[i_inner].z - nativeVectors[j].z
                        localTotal += sqrt(dx * dx + dy * dy + dz * dz)
                    }
                }
                return localTotal
            }
        }

        var finalTotal: Double = 0.0
        for await partialResult in group {
            finalTotal += partialResult
        }
        return finalTotal
    }
}

@MainActor
public let arginfo_total_pairwise_distance: [zend_internal_arg_info] = [
    ZEND_BEGIN_ARG_INFO_EX(
        name: "total_pairwise_distance",
        return_reference: false, 
        required_num_args: 1
    ),
    ZEND_ARG_INFO(pass_by_ref: false, name: "vectors")
]
@_cdecl("zif_total_pairwise_distance")
public func zif_total_pairwise_distance(
    _ execute_data: UnsafeMutablePointer<zend_execute_data>?,
    _ return_value: UnsafeMutablePointer<zval>?
) {
    var vectorsParam: UnsafeMutablePointer<zval>? = nil
    guard let return_value = return_value else { return }

    do {
        guard var state = ZEND_PARSE_PARAMETERS_START(min: 1, max: 1, execute_data: execute_data) else { return }
        try Z_PARAM_ARRAY(state: &state, dest: &vectorsParam)
        try ZEND_PARSE_PARAMETERS_END(state: state)
    } catch { return }

    guard let vectorsArrayZval = vectorsParam, let vector3_ce = V3State.shared.ce else { return }

    var nativeVectors: [Vector3] = []
    let vectorHashTable = Z_ARRVAL_P(vectorsArrayZval)
    nativeVectors.reserveCapacity(Int(zend_hash_num_elements(vectorHashTable)))

    ZEND_HASH_FOREACH_VAL(vectorHashTable) { vectorZval in
        guard Z_TYPE_P(vectorZval) == IS_OBJECT, Z_OBJCE_P(vectorZval) == vector3_ce else {
            return
        }
        let intern = fetchObject(Z_OBJ_P(vectorZval))
        nativeVectors.append(intern.pointee.vector3)
    }

    let resultBox = ResultBox<Double>()
    let semaphore = DispatchSemaphore(value: 0)

    Task {
        let distance = await calculateTotalPairwiseDistanceParallel(vectors: nativeVectors)
        resultBox.set(distance)
        semaphore.signal()
    }

    semaphore.wait()

    let finalDistance = resultBox.get() ?? 0.0
    RETURN_DOUBLE(return_value, finalDistance)
}

@_cdecl("vector3__construct")
public func vector3__construct(_ execute_data: UnsafeMutablePointer<zend_execute_data>?, _ _: UnsafeMutablePointer<zval>?) {
    let intern = fetchObject(UnsafeMutablePointer(mutating: execute_data?.pointee.This.value.obj))
    var x: CDouble = 0, y: CDouble = 0, z: CDouble = 0
    var x_is_null: CBool = true, y_is_null: CBool = true, z_is_null: CBool = true
    do {
        guard var state = ZEND_PARSE_PARAMETERS_START(min: 0, max: 3, execute_data: execute_data) else { return }
        Z_PARAM_OPTIONAL(state: &state)
        try Z_PARAM_DOUBLE_OR_NULL(state: &state, dest: &x, isNull: &x_is_null)
        try Z_PARAM_DOUBLE_OR_NULL(state: &state, dest: &y, isNull: &y_is_null)
        try Z_PARAM_DOUBLE_OR_NULL(state: &state, dest: &z, isNull: &z_is_null)
        try ZEND_PARSE_PARAMETERS_END(state: state)
    } catch { return }
    if x_is_null { x = 0.0 }; if y_is_null { y = 0.0 }; if z_is_null { z = 0.0 }
    intern.pointee.vector3 = Vector3(x: Double(x), y: Double(y), z: Double(z))
}

public func php_raylib_vector3_startup(type: CInt, module_number: CInt) {
    let S = V3State.shared
    var ce = zend_class_entry()

    let src = zend_std_handlers_ptr_shim()
    S.handlersPtr.pointee = src.pointee
    S.handlersPtr.pointee.offset = Int32(UInt32(MemoryLayout.offset(of: \php_raylib_vector3_object.std)!))
    S.handlersPtr.pointee.free_obj = php_raylib_vector3_free_storage
    S.handlersPtr.pointee.clone_obj = php_raylib_vector3_clone
    S.handlersPtr.pointee.get_property_ptr_ptr = php_raylib_vector3_get_property_ptr_ptr
    S.handlersPtr.pointee.get_gc = php_raylib_vector3_get_gc
    S.handlersPtr.pointee.get_properties = php_raylib_vector3_get_properties
    S.handlersPtr.pointee.read_property = php_raylib_vector3_read_property
    S.handlersPtr.pointee.write_property = php_raylib_vector3_write_property
    S.handlersPtr.pointee.has_property = php_raylib_vector3_has_property

    var methods: [zend_function_entry] = {
        var entries = [zend_function_entry]()
        entries.append(PHP_ME("Vector3", "__construct", vector3__construct, arginfo_vector3__construct, ZEND_ACC_PUBLIC))
        entries.append(PHP_FE_END())
        return entries
    }()

    methods.withUnsafeMutableBufferPointer { buf in
        INIT_NS_CLASS_ENTRY(&ce, "raylib", "Vector3", buf.baseAddress)
    }
    S.ce = zend_register_internal_class(&ce)
    S.ce?.pointee.create_object = php_raylib_vector3_new

    zend_hash_init(S.propHandlersPtr, 0, nil, php_raylib_vector3_free_prop_handler, true)
    "x".withCString { k in php_raylib_vector3_register_prop_handler(S.propHandlersPtr, k, php_raylib_vector3_get_x, php_raylib_vector3_set_x) }
    "y".withCString { k in php_raylib_vector3_register_prop_handler(S.propHandlersPtr, k, php_raylib_vector3_get_y, php_raylib_vector3_set_y) }
    "z".withCString { k in php_raylib_vector3_register_prop_handler(S.propHandlersPtr, k, php_raylib_vector3_get_z, php_raylib_vector3_set_z) }
}



@MainActor
public func vector3_functions_add_entries(builder: inout FunctionListBuilder) {
    builder.add(
        namespace: "raylib", 
        name: "vector3_sum", 
        handler: zif_arginfo_vector3_sum, 
        arg_info: arginfo_vector3_sum
    )

    builder.add(
        namespace: "raylib",
        name: "total_pairwise_distance",
        handler: zif_total_pairwise_distance,
        arg_info: arginfo_total_pairwise_distance
    )
}