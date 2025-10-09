+++
draft = false
title = 'PHP Arrays In Swift'
math = true
+++

# Working with PHP Arrays in Swift 🚀

This guide explains how to use a set of helper methods to safely iterate over PHP arrays in Swift. These methods are provided as an `extension` on `UnsafeMutablePointer<zend_array>`, which means you can call them directly on the result of `Z_ARRVAL_P(...)`.

The goal is to provide a simple, type-safe, and idiomatic Swift interface that handles the complex C-level boilerplate for you.

---
## Prerequisites: The `ZendObjectContainer` Protocol

Before you can iterate over your custom PHP objects, the Swift struct that defines its memory layout **must** conform to the `ZendObjectContainer` protocol. This is essential for the helper functions to correctly calculate memory offsets.

**1. The Protocol Definition**
This protocol should be available in your project.
```swift
public protocol ZendObjectContainer {
    var std: zend_object { get set }
    static var stdOffset: Int { get }
}
```

**2. Example Conformance**
For your custom object struct, ensure `std` is a stored property and add the conformance in an extension.

```swift
// The struct that matches your PHP object's memory layout
@frozen public struct MyPHPObject {
    var myCustomData: String
    public var std: zend_object // Must be a stored property
}

// Add conformance in an extension
extension MyPHPObject: ZendObjectContainer {
    public static var stdOffset: Int {
        MemoryLayout<Self>.offset(of: \.std)!
    }
}
```

---
## Iterating Over Values Only

These methods are for when you only care about the values in an array and not their keys.

### `withEachObject`
Iterates over the array and yields only the elements that are objects of a specific class.

**Signature:**
```swift
func withEachObject<T: ZendObjectContainer>(
    ofType ce: UnsafeMutablePointer<zend_class_entry>?,
    as objectType: T.Type,
    body: (UnsafeMutablePointer<T>) -> Void
)
```

**Example:**
```swift
var nativeObjects: [MyPHPObject] = []
let ht = Z_ARRVAL_P(phpArrayZval)
let myClassEntry = MyState.shared.ce // Get your class entry

ht.withEachObject(ofType: myClassEntry, as: MyPHPObject.self) { intern in
    // 'intern' is a correctly typed pointer to your Swift struct
    nativeObjects.append(intern.pointee)
}
```

---
### `withEachString`, `withEachInt`, `withEachDouble`
Iterates over the array, yielding only the values that match a specific scalar type.

**Signatures:**
```swift
func withEachString(body: (String) -> Void)
func withEachInt(body: (Int) -> Void)
func withEachDouble(body: (Double) -> Void)
```

**Example:**
```swift
var names: [String] = []
let ht = Z_ARRVAL_P(phpArrayZval)

ht.withEachString { name in
    names.append(name)
}
```

---
### `forEach` (Value-Only)
The "power-user" iterator. It yields a pointer to every `zval` in the array, leaving type checking up to you.

**Signature:**
```swift
func forEach(body: (UnsafeMutablePointer<zval>) -> Void)
```

**Example:**
```swift
let ht = Z_ARRVAL_P(phpArrayZval)

ht.forEach { valuePtr in
    switch Z_TYPE_P(valuePtr) {
    case IS_STRING:
        print("Found a string")
    case IS_LONG:
        print("Found an integer: \(Z_LVAL_P(valuePtr))")
    default:
        print("Found another type")
    }
}
```

---
## Iterating Over Keys and Values

These methods are for when you need both the key and the value, such as when processing an associative array.

### Helper Type: `PHPArrayKey`
When iterating with keys, the key is provided as a `PHPArrayKey` enum. This allows you to safely handle both string and integer keys.

**Definition:**
```swift
public enum PHPArrayKey {
    case int(UInt)
    case string(UnsafeMutablePointer<zend_string>)
}
```

---
### `forEach` (Key-Value)
This is the base key-value iterator. It yields the `PHPArrayKey` and the raw `zval` pointer for every element.

**Signature:**
```swift
func forEach(body: (PHPArrayKey, UnsafeMutablePointer<zval>) -> Void)
```

**Example:**
```swift
let ht = Z_ARRVAL_P(phpArrayZval)

ht.forEach { key, valuePtr in
    if case .string(let keyStr) = key, String(zendString: keyStr) == "my_key" {
        // Found the key "my_key", now inspect its value
        if Z_TYPE_P(valuePtr) == IS_LONG {
            // ...
        }
    }
}
```

---
### Specialized Key-Value Iterators
These are powerful overloads that provide both the key and a **type-safe value**, filtering the array for you.

**Signatures:**
```swift
func withEachString(body: (PHPArrayKey, String) -> Void)
func withEachInt(body: (PHPArrayKey, Int) -> Void)
func withEachDouble(body: (PHPArrayKey, Double) -> Void)
func withEachObject<T: ZendObjectContainer>(
    ofType ce: UnsafeMutablePointer<zend_class_entry>?,
    as objectType: T.Type,
    body: (PHPArrayKey, UnsafeMutablePointer<T>) -> Void
)
```

**Example:**
```swift
// Given a PHP array: $config = ["host" => "localhost", "port" => 8080];
let ht = Z_ARRVAL_P(configZval)
var config = [String: Any]()

// Use the specialized iterator for strings
ht.withEachString { key, value in
    if case .string(let keyStr) = key {
        config[String(zendString: keyStr)!] = value
    }
}

// Use the specialized iterator for integers
ht.withEachInt { key, value in
    if case .string(let keyStr) = key {
        config[String(zendString: keyStr)!] = value
    }
}

// config now holds ["host": "localhost", "port": 8080]
```