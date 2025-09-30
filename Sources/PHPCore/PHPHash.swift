import Foundation

let HASH_FLAG_PACKED: UInt32 = 1 << 2

func HT_FLAGS(_ ht: UnsafeMutablePointer<HashTable>) -> UInt32 {
    return ht.pointee.u.flags
}

func HT_IS_PACKED(_ ht: UnsafeMutablePointer<HashTable>) -> Bool {
    return (HT_FLAGS(ht) & HASH_FLAG_PACKED) != 0
}

public func ZVAL_EMPTY_ARRAY(_ z: UnsafeMutablePointer<zval>?) {
    guard let z = z else { return }
    
    withUnsafePointer(to: zend_empty_array) { emptyArrayPtr in
        let mutablePtr = UnsafeMutablePointer(mutating: emptyArrayPtr)
        z.pointee.value.arr = mutablePtr
    }
    
    z.pointee.u1.type_info = UInt32(IS_ARRAY)
}

public func ZEND_HASH_FOREACH_STR_KEY_VAL(
    _ ht: UnsafeMutablePointer<HashTable>,
    body: (_ key: UnsafeMutablePointer<zend_string>?, _ val: UnsafeMutablePointer<zval>) -> Void
) {
    ZEND_HASH_FOREACH_FROM(ht: ht, indirect: 0, from: 0) { (key, val, _) in
        if let val = val {
            body(key, val)
        }
    }
}

public func ZEND_HASH_FOREACH(ht: UnsafeMutablePointer<HashTable>, indirect: Int32) {
    ZEND_HASH_FOREACH_FROM(ht: ht, indirect: indirect, from: 0) { (key, val, _) in
        // No operation here, this is just to forward the call
    }
}

public func ZEND_HASH_FOREACH_FROM(
    ht: UnsafeMutablePointer<HashTable>,
    indirect: Int32,
    from: Int,
    body: (_ key: UnsafeMutablePointer<zend_string>?, _ val: UnsafeMutablePointer<zval>?, _ hash: zend_ulong) -> Void
) {
    let _size = ZEND_HASH_ELEMENT_SIZE(ht)
    var _idx = from
    var __z = ZEND_HASH_ELEMENT_EX(ht, _idx, _size)
    var _count = Int(ht.pointee.nNumUsed) - _idx

    // Like PHP's macro `for(; _count > 0; _count--) {}` - see end of while loop for the `_count--` part
    while _count > 0 {
        var _z = __z
        var __key: UnsafeMutablePointer<zend_string>? = nil
        var __h: zend_ulong = 0

        if HT_IS_PACKED(ht) {
            __z = __z?.advanced(by: 1)
            __h = zend_ulong(_idx) // Hash or index in packed tables
            _idx += 1
        } else {
            let _p = __z!.withMemoryRebound(to: Bucket.self, capacity: 1) { $0 }
            __z = _p.advanced(by: 1).withMemoryRebound(to: zval.self, capacity: 1) { $0 }
            __h = _p.pointee.h
            __key = _p.pointee.key

            if indirect != 0 && Z_TYPE_P(_z!) == IS_INDIRECT {
                _z = Z_INDIRECT_P(_z!)
            }
        }

        if Z_TYPE_P(_z!) == IS_UNDEF {
            continue
        }

        // Pass `__h` into the closure
        body(__key, _z, __h)

        // Deincrement count like PHP's macro `for(; _count > 0; _count--) {}`
        _count -= 1
    }
}

public func ZEND_HASH_FOREACH_VAL(
    _ ht: UnsafeMutablePointer<HashTable>,
    body: (_ val: UnsafeMutablePointer<zval>) -> Void
) {
    let _size = ZEND_HASH_ELEMENT_SIZE(ht)  // Get size of each element in the hash table
    var _count = Int(ht.pointee.nNumUsed)   // Get the number of elements used
    var _z = ht.pointee.arPacked            // Start from the first element (packed)

    while _count > 0 {
        // Process the current zval
        if Z_TYPE_P(_z!) == IS_UNDEF {
            _z = ZEND_HASH_NEXT_ELEMENT(_z, _size)  // Move to the next element
            _count -= 1
            continue
        }

        // Pass the current value (zval) to the closure
        body(_z!)

        // Move to the next element
        _z = ZEND_HASH_NEXT_ELEMENT(_z, _size)
        _count -= 1
    }
}

public func ZEND_HASH_NEXT_ELEMENT(_ _el: UnsafeMutablePointer<zval>?, _ _size: Int) -> UnsafeMutablePointer<zval>? {
    return _el.map { UnsafeMutableRawPointer($0).advanced(by: _size).assumingMemoryBound(to: zval.self) }
}

public func ZEND_HASH_ELEMENT_SIZE(_ ht: UnsafeMutablePointer<HashTable>) -> Int {
    return MemoryLayout<zval>.size + ((HT_FLAGS(ht) & HASH_FLAG_PACKED) == 0 ? MemoryLayout<Bucket>.size - MemoryLayout<zval>.size : 0)
}

public func ZEND_HASH_ELEMENT_EX(_ ht: UnsafeMutablePointer<HashTable>, _ _idx: Int, _ _size: Int) -> UnsafeMutablePointer<zval>? {
    return UnsafeMutablePointer<zval>(bitPattern: UInt(bitPattern: ht.pointee.arPacked) + UInt(_idx * _size))
}

public struct PhpArrayValIter: Sequence, IteratorProtocol {
    var hashTable: UnsafeMutablePointer<HashTable> // Non-optional
    var idx: Int = 0
    let size: Int
    var count: Int

    public init(_ hashTable: UnsafeMutablePointer<HashTable>) {
        self.hashTable = hashTable
        self.size = ZEND_HASH_ELEMENT_SIZE(hashTable)
        self.count = Int(hashTable.pointee.nNumUsed)
    }

    public mutating func next() -> UnsafeMutablePointer<zval>? {
        while count > 0 {
            let val = ZEND_HASH_ELEMENT_EX(hashTable, idx, size)
            idx += 1
            count -= 1

            // Skip undefined values
            if Z_TYPE_P(val!) == IS_UNDEF {
                continue
            }

            return val
        }
        return nil
    }
}

public struct PhpZValValIter: Sequence, IteratorProtocol {
    private var iterator: PhpArrayValIter?

    public init(_ zval: UnsafeMutablePointer<zval>) {
        if Z_TYPE_P(zval) == IS_ARRAY {
            self.iterator = PhpArrayValIter(Z_ARRVAL_P(zval))
        } else {
            self.iterator = nil
        }
    }

    public mutating func next() -> UnsafeMutablePointer<zval>? {
        return iterator?.next()
    }
}
