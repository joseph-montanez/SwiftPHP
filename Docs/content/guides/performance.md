+++
draft = false
title = 'Performance'
math = true
+++

# Performance

Swift offers great performance since its a compiled language with parallel and async features that are type checked. All while having no garbage collection.

## Benchmark Pairwise Distance

Pairwise Distance calculates the distance between every unique pair of vectors

$$d = \sqrt{(x_2 - x_1)^2 + (y_2 - y_1)^2 + (z_2 - z_1)^2}$$

### Result

| Version                   | Vector Count | Pairwise Calculations | Execution Time | Estimated Time at 50k Vectors   | Speedup                |
| :------------------------ | :----------- | :-------------------- | :------------- | :------------------------------ | :--------------------- |
| **PHP** (Baseline)        | 2,000        | ~2 Million            | ~1.47 s        | **~15.3 minutes***              | 1x                     |
| **Swift (Single Core)**   | 50,000       | ~1.25 Billion         | 29.30 s        | 29.30 seconds                   | **30.99x** faster      |
| **Swift (Multi-core)**    | 50,000       | ~1.25 Billion         | 7.00 s         | 7.00 seconds                    | **133.25x** faster     |


### PHP Benchmark Test

```php
$numVectors = 50_000;

echo "Generating test data...\n";
$vectors = [];
for ($i = 0; $i < $numVectors; $i++) {
    $vectors[] = new \raylib\Vector3(
        rand(0, 100) / 10.0,
        rand(0, 100) / 10.0,
        rand(0, 100) / 10.0
    );
}
echo "Test data generated.\n\n";



$smallVectorSet = array_slice($vectors, 0, 2000);

printf("\n--- Benchmarking Pairwise Distance ---\n");
printf("Running PHP version with %s vectors...\n", number_format(count($smallVectorSet)));
$startPhp = microtime(true);
$phpDistance = php_total_pairwise_distance($smallVectorSet);
$endPhp = microtime(true);
$phpTime = $endPhp - $startPhp;
printf("PHP Time: %.4f seconds\n", $phpTime);


printf("\nRunning Swift version with %s vectors...\n", number_format(count($vectors)));
$startSwift = microtime(true);
$swiftDistance = \raylib\total_pairwise_distance($vectors); // Your new namespaced function
$endSwift = microtime(true);
$swiftTime = $endSwift - $startSwift;
printf("Swift Time: %.4f seconds\n", $swiftTime);

$speedup = ($phpTime / count($smallVectorSet)**2) / ($swiftTime / count($vectors)**2);
printf("\n✅ Swift extension is roughly %.2f times faster on a per-operation basis.\n", $speedup);
```

### Pure PHP Implementation
PHP has no built-in threading or parallel features to speed this up.
```php
/**
 * Calculates the sum of the distances between every unique 
 * pair of vectors in the array. This is an O(n^2) operation.
 */
function php_total_pairwise_distance(array $vectors): float
{
    $totalDistance = 0.0;
    $count = count($vectors);

    for ($i = 0; $i < $count; $i++) {
        for ($j = $i + 1; $j < $count; $j++) {
            $dx = $vectors[$i]->x - $vectors[$j]->x;
            $dy = $vectors[$i]->y - $vectors[$j]->y;
            $dz = $vectors[$i]->z - $vectors[$j]->z;
            $totalDistance += sqrt($dx * $dx + $dy * $dy + $dz * $dz);
        }
    }

    return $totalDistance;
}
```

### SwiftPHP Native PHP Extension Implementation
```swift
/**
 * A simple, thread-safe container to hold a single value.
 *
 * Why a class?
 * A class is a reference type, so we can pass an instance of it into a concurrent
 * Task and have that task modify the original object's contents.
 *
 * Why final?
 * `final` tells the compiler that this class will never be subclassed. This is a
 * performance optimization, as it allows the compiler to use direct function
 * calls (static dispatch) instead of more complex dynamic dispatch.
 *
 * Why generic (`<T>`)?
 * This makes the box reusable. It can hold any type of value (a Double,
 * a String, a custom struct, etc.), not just the Double needed for this specific function.
 *
 * Why `@unchecked Sendable`?
 * `Sendable` is a protocol that marks a type as being safe to share across
 * concurrent threads. Classes are not `Sendable` by default because they represent
 * shared, mutable state, which is a primary source of data races.
 * `@unchecked` is a promise to the compiler: "I, the developer, guarantee that
 * I have made this class thread-safe myself." The compiler will then trust us
 * and allow this object to be passed into a concurrent `Task`.
 */
final class ResultBox<T>: @unchecked Sendable {
    /// The value being stored. It's private to ensure all access goes
    /// through our thread-safe `get()` and `set()` methods. It's an optional
    /// because it starts with no value.
    private var value: T?
    
    /// The locking mechanism. `NSLock` is a basic mutex (mutal exclusion lock).
    /// It ensures that only one thread can be executing the code inside the
    /// locked section at any given time, preventing data races.
    private let lock = NSLock()

    /**
     * Safely sets the value from any thread.
     */
    func set(_ value: T) {
        // Acquire the lock. If another thread already holds the lock, this
        // line will pause and wait until the lock is released.
        lock.lock()
        
        // `defer` is a powerful Swift feature. The code inside the `defer` block
        // is guaranteed to run at the end of the current scope (i.e., just
        // before the `set` function returns), no matter what happens. This
        // ensures the lock is *always* released, even if an error occurred.
        defer { lock.unlock() }
        
        // Now that we have the lock, it's safe to modify the shared value.
        self.value = value
    }

    /**
     * Safely retrieves the value from any thread.
     */
    func get() -> T? {
        lock.lock()
        defer { lock.unlock() }
        return self.value
    }
}

/**
 * Calculates the total pairwise distance in parallel.
 *
 * Why `async`?
 * This marks the function as asynchronous. It can perform long-running, concurrent
 * work without blocking the thread that calls it. The `await` keyword is used
 * to call it, which allows the system to suspend this function and run other
 * code while waiting for the parallel tasks to complete.
 */
func calculateTotalPairwiseDistanceParallel(vectors nativeVectors: [Vector3]) async -> Double {
    let count = nativeVectors.count
    // A simple guard to prevent trying to calculate with fewer than 2 vectors.
    guard count >= 2 else { return 0.0 }

    // Why `ProcessInfo`?
    // This dynamically queries the system for the number of active CPU cores.
    // This makes the code adaptive; it will use 4 cores on a 4-core machine,
    // and 16 cores on a 16-core machine, ensuring optimal performance.
    let processorCount = ProcessInfo.processInfo.activeProcessorCount
    
    // Why this math for `chunkSize`?
    // This is a standard integer math formula to divide a number of items (`count`)
    // into a number of groups (`processorCount`), correctly handling any remainders.
    // It ensures that all vectors are processed.
    let chunkSize = (count + processorCount - 1) / processorCount

    // Why `withTaskGroup`?
    // This is the primary tool in Swift for dynamic, structured concurrency. It
    // creates a scope where you can spin up multiple child tasks that run in
    // parallel. The `await` on this line ensures the function will not proceed
    // until *all* the tasks added to the `group` have completed.
    return await withTaskGroup(of: Double.self, returning: Double.self) { group in

        // This loop creates the work for each core. It doesn't do the work itself.
        for i in stride(from: 0, to: count, by: chunkSize) {
            let end = min(i + chunkSize, count)
            let chunkRange = i..<end

            // Why `group.addTask`?
            // This submits a block of code (a closure) to the Swift Concurrency
            // runtime. The runtime will schedule this task to run on a background
            // thread, typically from a cooperative thread pool sized to the
            // number of CPU cores.
            group.addTask {
                // Why `localTotal`?
                // This is a critical pattern for parallelism. Each thread calculates
                // its own partial sum. This avoids having all threads trying to
                // update a single shared variable, which would require locking
                // and create a massive performance bottleneck (lock contention).
                var localTotal: Double = 0.0

                // This is the actual "heavy lifting." Each core processes its
                // assigned `chunkRange` of the outer loop. The inner loop remains
                // the same, but the overall work is now split across many cores.
                for i_inner in chunkRange {
                    for j in (i_inner + 1)..<count {
                        let dx = nativeVectors[i_inner].x - nativeVectors[j].x
                        let dy = nativeVectors[i_inner].y - nativeVectors[j].y
                        let dz = nativeVectors[i_inner].z - nativeVectors[j].z
                        localTotal += sqrt(dx * dx + dy * dy + dz * dz)
                    }
                }
                // Each task finishes and returns its own result to the group.
                return localTotal
            }
        }

        // Why `for await`?
        // This loop asynchronously waits for the child tasks in the group to
        // complete. As each task finishes and returns its `localTotal`, this
        // loop will receive the value. This is how results are collected.
        var finalTotal: Double = 0.0
        for await partialResult in group {
            // The summation happens here, safely on the parent task's thread,
            // after the parallel work is done.
            finalTotal += partialResult
        }
        return finalTotal
    }
}

// Why `@MainActor`?
// This global constant is marked as belonging to the Main Actor. This is a
// concurrency safety feature. It ensures that if this (or any other) global
// state were ever modified, all access would be synchronized through the main
// thread, preventing data races. For a `let` constant, it's less critical
// but is good practice.
@MainActor
public let arginfo_total_pairwise_distance: [zend_internal_arg_info] = [
    // Describes the function itself to PHP's reflection and error-handling systems.
    ZEND_BEGIN_ARG_INFO_EX(
        name: "total_pairwise_distance", // The function name PHP sees
        return_reference: false,         // The function returns a value, not a reference
        required_num_args: 1             // It must be called with at least 1 argument
    ),
    // Describes the first argument.
    ZEND_ARG_INFO(
        pass_by_ref: false,              // The argument is passed by value
        name: "vectors"                  // The argument name is "vectors"
    )
]
// Why `@_cdecl`?
// This attribute exposes the Swift function to the C world. It gives the
// function a simple, predictable symbol name ("zif_total_pairwise_distance") in the
// compiled library file, which is what the PHP engine looks for when loading
// the extension. "zif" stands for "Zend Internal Function".
@_cdecl("zif_total_pairwise_distance")
public func zif_total_pairwise_distance(
    _ execute_data: UnsafeMutablePointer<zend_execute_data>?,
    _ return_value: UnsafeMutablePointer<zval>?
) {
    var vectorsParam: UnsafeMutablePointer<zval>? = nil
    guard let return_value = return_value else { return }

    // --- 1. Standard Parameter Parsing ---
    // This block uses the argument parsing API to safely extract the expected
    // array argument from PHP. If the user passes the wrong type or number of
    // arguments, this will fail gracefully and throw an error up to PHP.
    do {
        guard var state = ZEND_PARSE_PARAMETERS_START(min: 1, max: 1, execute_data: execute_data) else { return }
        try Z_PARAM_ARRAY(state: &state, dest: &vectorsParam)
        try ZEND_PARSE_PARAMETERS_END(state: state)
    } catch { return }

    guard let vectorsArrayZval = vectorsParam, let vector3_ce = V3State.shared.ce else { return }

    // --- 2. Copy PHP Objects into a Native Swift Array ---
    // This is the most important optimization for a parallel function.
    // Why copy? For two reasons:
    // 1. PERFORMANCE: Accessing data from PHP objects is slow and involves API
    //    calls into the Zend Engine. Copying the raw data into a native Swift
    //    array creates a tight, contiguous, cache-friendly block of memory.
    //    This makes the billions of calculations in the parallel loop orders
    //    of magnitude faster.
    // 2. THREAD SAFETY: PHP's internal data structures are NOT safe to be
    //    accessed by multiple threads simultaneously. Copying the data creates
    //    a safe, isolated snapshot that our parallel Swift code can work on
    //    without risk of crashing or corrupting the PHP engine.
    var nativeVectors: [Vector3] = []
    let vectorHashTable = Z_ARRVAL_P(vectorsArrayZval)
    
    // Why `reserveCapacity`?
    // A small performance optimization. It pre-allocates enough memory for the
    // entire array at once, avoiding the overhead of resizing the array multiple
    // times as elements are appended.
    nativeVectors.reserveCapacity(Int(zend_hash_num_elements(vectorHashTable)))

    // `ZEND_HASH_FOREACH_VAL` is the Swift wrapper for iterating over a PHP array.
    ZEND_HASH_FOREACH_VAL(vectorHashTable) { vectorZval in
        // We verify that each item in the array is the correct object type.
        guard Z_TYPE_P(vectorZval) == IS_OBJECT, Z_OBJCE_P(vectorZval) == vector3_ce else {
            // In a real-world scenario, you might want to throw a PHP warning here.
            return
        }
        let intern = fetchObject(Z_OBJ_P(vectorZval))
        // This is the fast, 24-byte memory copy.
        nativeVectors.append(intern.pointee.vector3)
    }


    // --- 3. The "Async-to-Sync" Bridge ---
    // This is the pattern used to call our `async` parallel function from this
    // synchronous C-style function.
    let resultBox = ResultBox<Double>()
    let semaphore = DispatchSemaphore(value: 0)

    // Why `Task`?
    // This kicks off the asynchronous work on a background thread pool.
    // The main thread (the one PHP is on) does not wait here; it continues on.
    Task {
        let distance = await calculateTotalPairwiseDistanceParallel(vectors: nativeVectors)
        resultBox.set(distance)
        // `signal()` tells the semaphore that the work is done, "waking up"
        // any thread that is waiting on it.
        semaphore.signal()
    }

    // Why `semaphore.wait()`?
    // This is the crucial blocking call. It PAUSES the main PHP thread right here
    // and waits until `semaphore.signal()` is called from the background task.
    // Without this, the function would return to PHP immediately with a zero
    // result, long before the calculation was finished.
    semaphore.wait()

    // --- 4. Return the Final Value to PHP ---
    // We safely retrieve the result from our thread-safe box.
    let finalDistance = resultBox.get() ?? 0.0
    // `RETURN_DOUBLE` is a helper/macro that converts the Swift `Double` into
    // a PHP `zval` of type IS_DOUBLE and sets it as the function's return value.
    RETURN_DOUBLE(return_value, finalDistance)
}

```