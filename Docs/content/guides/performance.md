+++
draft = false
title = 'Performance Comparison'
math = true
+++

# Performance Comparison

Swift offers great performance since its a compiled language with parallel and async features that are type checked. All while having no garbage collection.

## Benchmark Pairwise Distance

Pairwise Distance calculates the distance between every unique pair of vectors

$$d = \sqrt{(x_2 - x_1)^2 + (y_2 - y_1)^2 + (z_2 - z_1)^2}$$

### Result (Debug Mode)

The following is based on 50,000 vectors and ~1.25 billion calcuations.

| Version | Processor / OS | Execution Time | Estimated Time at 50 k Vectors | Speedup vs PHP |
| :--- | :--- | :--- | :--- | :--- |
| **PHP (Baseline)** | Apple M4 Mac mini (macOS 15) | 953.98 s | **~15.9 minutes** | 1× |
| **Swift (Single Core)** | Apple M4 Mac mini (macOS 15) | 8.2841 s | 8.2841 s | **~115.16×** |
| **Swift (Multi-Core)** | Apple M4 Mac mini (macOS 15) | 2.1486 s | 2.1486 s | **~444.00×** |
| **PHP (Baseline)** | Snapdragon X1P42100 (Windows 11) | 1.2340 s | **~12.9 minutes** | 1× |
| **Swift (Single Core)** | Snapdragon X1P42100 (Windows 11) | 11.0950 s | 11.0950 s | **~68.35×** |
| **Swift (Multi-Core)** | Snapdragon X1P42100 (Windows 11) | 3.0551 s | 3.0551 s | **~252.45×** |


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
 * A highly optimized function to distribute N items into P parts as evenly as possible.
 *
 * Why `@inline(__always)`?
 * This is an aggressive compiler optimization directive. It tells the compiler to
 * copy and paste the machine code for this function directly into the place
 * where it's called, rather than making a traditional function call. This eliminates
 * the tiny but measurable overhead of setting up a function call (pushing arguments
 * onto the stack, jumping to a new memory address, and returning). For a small,
 * frequently-called function like this, inlining provides a speed boost.
 */
@inline(__always)
private func chunkBounds(count: Int, parts: Int, index: Int) -> Range<Int> {
    // Why this math? This is a classic, highly efficient way to partition work.
    // It avoids floating-point math and ensures perfect distribution.
    
    // `base`: The minimum number of items each part will handle.
    // e.g., 100 items / 8 parts = 12. Each part gets at least 12.
    let base = count / parts
    
    // `rem`: The number of "leftover" items that need to be distributed.
    // e.g., 100 % 8 = 4. There are 4 extra items to hand out.
    let rem = count % parts
    
    // `start`: The starting index for the current part (`index`).
    // Each part gets `index * base` items from the base distribution.
    // `min(index, rem)` is the clever part: it gives one extra "leftover" item
    // to each of the first `rem` parts.
    // e.g., part 3 (index=3) gets 3*12 + min(3, 4) = 36 + 3 = 39.
    let start = index * base + min(index, rem)
    
    // `end`: The exclusive ending index.
    // It's the `start` plus the `base` size, plus 1 if this part is one of the
    // first `rem` parts that received an extra item. This ensures the range
    // has the correct length.
    let end = start + base + (index < rem ? 1 : 0)
    
    return start..<end
}

/**
 * A simple, raw pointer container.
 *
 * Why a struct?
 * Structs are value types in Swift, meaning they are typically stack-allocated
 * and copied on assignment. This makes them very fast and lightweight. Here, it's
 * just a thin wrapper around a raw pointer.
 *
 * Why `@unchecked Sendable`?
 * This is a promise to the compiler that we, the developers, guarantee this type
 * is safe to use across concurrent threads. We can make this promise because we
 * know each thread will only ever write to its own unique index (`partials.base[part]`),
 * so there will be no data races. This bypasses compiler safety checks for a
 * performance gain.
 *
 * Why `UnsafeMutablePointer`?
 * This is the "bare metal" way to access memory in Swift. It's a raw memory
 * address, similar to a `double*` in C. It provides maximum performance by
 * bypassing all of Swift's safety features:
 * - No automatic reference counting (ARC).
 * - No bounds checking on access.
 * - No memory lifetime management.
 * We are responsible for allocating, initializing, and deallocating the memory manually.
 */
private struct Partials: @unchecked Sendable { let base: UnsafeMutablePointer<Double> }

/**
 * Calculates the total pairwise distance using a low-level, highly optimized parallel approach.
 */
func calculateTotalPairwiseDistanceParallel(_ vectors: [Vector3]) -> Double {
    let n = vectors.count
    if n < 2 { return 0 }
    
    // Why `max(1, ...)`? A simple guard to prevent dividing by zero if the system
    // somehow reported zero cores.
    let cores = max(1, ProcessInfo.processInfo.activeProcessorCount)
    
    // Why `min(cores, n)`? An optimization to avoid creating more threads than
    // there are items to process in the outer loop, which would be wasteful.
    let parts = min(cores, n)

    // --- Manual Memory Management ---
    // 1. Allocate: We ask the system for a raw, uninitialized block of memory
    //    large enough to hold a `Double` for each parallel part.
    let ptr = UnsafeMutablePointer<Double>.allocate(capacity: parts)
    
    // 2. Initialize: We explicitly set the allocated memory to a known state (all zeros).
    //    Accessing uninitialized memory is undefined behavior.
    ptr.initialize(repeating: 0, count: parts)
    
    // Create our thin wrapper around the raw pointer.
    let partials = Partials(base: ptr)

    // Why `DispatchQueue.concurrentPerform`?
    // This is the star of the show. It's a highly optimized GCD function
    // specifically for "fork-join" parallelism. It executes the code in its closure
    // `iterations` times, distributing those executions across all available CPU
    // cores. Crucially, it is a *blocking* call: this line of code will not
    // finish and the function will not proceed until all `parts` have completed.
    // This avoids the massive overhead of an async-to-sync bridge (like a DispatchSemaphore).
    DispatchQueue.concurrentPerform(iterations: parts) { part in // `part` is the current iteration index (0, 1, 2, ...)
        
        // Each thread calculates its assigned range of the outer loop.
        let r = chunkBounds(count: n, parts: parts, index: part)
        
        // Why `local`? This is a critical performance pattern. Each thread accumulates
        // its own sub-total in a variable that is local to its own stack. This means
        // there is zero lock contention or synchronization needed during the main calculation.
        var local: Double = 0
        var i = r.lowerBound
        while i < r.upperBound {
            let a = vectors[i]
            // The inner loop still has to go to the end of the array. The parallelism
            // is only applied to the outer loop.
            var j = i + 1
            while j < n {
                let b = vectors[j]
                let dx = a.x - b.x
                let dy = a.y - b.y
                let dz = a.z - b.z
                // `squareRoot()` on a `Double` is often faster than the global `sqrt()` function.
                local += (dx*dx + dy*dy + dz*dz).squareRoot()
                j += 1
            }
            i += 1
        }
        
        // After all calculations are done, each thread performs a single,
        // uncontested write to its designated slot in the shared memory block.
        // e.g., thread 0 writes to base[0], thread 1 writes to base[1], etc.
        // Since no two threads write to the same index, no locks are needed.
        partials.base[part] = local
    }

    // --- Final Summation and Cleanup ---
    // At this point, `concurrentPerform` has finished and all threads have completed.
    // The `partials.base` pointer now holds all the sub-totals.
    var total: Double = 0
    for i in 0..<parts { total += partials.base[i] }
    
    // 3. Deinitialize: We tell Swift that we are done with the values in this memory.
    //    This is important for types that might have their own cleanup code. For `Double`,
    //    it's less critical but is correct and required practice.
    partials.base.deinitialize(count: parts)
    
    // 4. Deallocate: We return the raw memory block back to the system to prevent a memory leak.
    partials.base.deallocate()
    
    return total
}

// The PHP C-interop code remains the same, as its job is to prepare the native
// Swift array and then call the calculation function.

@MainActor
public let arginfo_total_pairwise_distance: [zend_internal_arg_info] = [
    ZEND_BEGIN_ARG_INFO_EX(name: "total_pairwise_distance", return_reference: false, required_num_args: 1),
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
    let ht = Z_ARRVAL_P(vectorsArrayZval)
    let expectedCount = Int(zend_hash_num_elements(ht))
    nativeVectors.reserveCapacity(expectedCount)
    
    ZEND_HASH_FOREACH_VAL(ht) { zv in
        var tmp = zval()
        ZVAL_COPY_DEREF(&tmp, zv)
        defer { zval_ptr_dtor(&tmp) }
        if Z_TYPE(tmp) == IS_OBJECT && Z_OBJCE(tmp) == vector3_ce {
            let intern = fetchObject(Z_OBJ(tmp))
            nativeVectors.append(intern.pointee.vector3)
        }
    }
    
    // This is a direct, synchronous call. The function blocks until the parallel
    // work is done and then returns the final result. No bridging is needed.
    let finalDistance = calculateTotalPairwiseDistanceParallel(nativeVectors)
    RETURN_DOUBLE(return_value, finalDistance)
}
```