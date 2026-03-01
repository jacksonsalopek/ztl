# ZTL HTML Templating Library - Performance Benchmarks

Comprehensive performance benchmarking suite to identify optimization boundaries for the ztl HTML templating library.

## Overview

This benchmark suite measures performance characteristics and identifies crossover points where various optimizations (SIMD, packed structs, etc.) become beneficial compared to the current scalar implementation.

**Current Performance Baseline**: ~80-85k RPS (11-12μs per render)

## Available Benchmarks

### 1. HTML Escaping (`html-escaping`)

Baseline performance measurement for HTML entity escaping using scalar implementation.

**What it measures:**
- Scalar two-pass algorithm (count + write)
- String sizes: 8, 16, 32, 64, 128, 256, 512, 1024 bytes
- Content patterns: 0%, 10%, 50% special characters

**Run it:**
```bash
zig build benchmark -- html-escaping
```

**Why no SIMD?**
Testing showed SIMD @Vector(16, u8) was 0-22% slower than scalar across all test cases:
- Vectorization setup overhead exceeds benefits
- Two-pass nature prevents effective SIMD utilization
- Sparse special characters mean most comparisons are wasted
- Scalar implementation is already optimal for this workload

**Key findings:**
- Scalar implementation is optimal for HTML escaping
- Two-pass algorithm (count + write) handles sparse special chars efficiently
- No benefit from SIMD vectorization for typical HTML content

### 2. Struct Packing (`struct-packing`)

Compares packed vs regular struct performance for Props, ARIAProps, and HTMXProps.

**What it measures:**
- Rendering performance comparison
- Memory layout impact on cache locality
- Struct size differences

**Run it:**
```bash
zig build benchmark -- struct-packing
```

**Notes:**
- Optional slices cannot be packed (no guaranteed memory representation)
- Tests alternative struct layouts
- Measures real-world rendering performance

### 3. Tag Cache (`tag-cache`)

Compares different tag cache lookup strategies.

**What it measures:**
- Perfect hash (current) vs linear search vs hash map
- Common tags (top 10) vs rare tags
- Mixed workload (80% common, 20% rare)
- Lookup time comparison

**Run it:**
```bash
zig build benchmark -- tag-cache
```

**Key findings:**
- Perfect hash provides O(1) lookup for cached tags
- Current implementation is optimal for common HTML tags
- Linear search acceptable for small tag sets
- HashMap overhead not justified for this use case

### 4. Buffer Growth (`buffer-growth`)

Tests different buffer allocation strategies.

**What it measures:**
- Default ArrayList growth vs pre-allocated buffers
- Fixed buffer streams for small templates
- Allocation counts and memory overhead
- Template sizes: small (~200 bytes), medium (~2KB), large (~20KB)

**Run it:**
```bash
zig build benchmark -- buffer-growth
```

**Key findings:**
- Pre-allocation reduces allocations significantly
- Default growth (1.5x) balances memory and reallocations
- Fixed buffer optimal for small, bounded templates
- Profile actual template sizes in production

## Running Benchmarks

### Run all benchmarks:
```bash
zig build benchmark
```

### Run specific benchmark:
```bash
zig build benchmark -- <benchmark-name>
```

Available benchmark names:
- `html-escaping`
- `struct-packing`
- `tag-cache`
- `buffer-growth`

### Build and run separately:
```bash
zig build
./zig-out/bin/benchmark html-escaping
```

## Benchmark Infrastructure

### Common Utilities

All benchmarks use shared utilities from `root.zig`:

- **Timer**: High-precision timing using `std.time.Timer`
- **AllocTracker**: Memory allocation profiling
- **Result**: Standardized result reporting
- **Stats**: Statistical analysis (avg, min, max, median)

### Example Usage

```zig
const benchmarks = @import("root.zig");
const Timer = benchmarks.Timer;
const Result = benchmarks.Result;
const Stats = benchmarks.Stats;

fn myBenchmark(allocator: std.mem.Allocator, iterations: usize, samples: usize) !Result {
    const times = try allocator.alloc(u64, samples);
    defer allocator.free(times);

    // Warmup
    for (0..100) |_| {
        // ... code to benchmark ...
    }

    // Run samples
    for (times) |*time| {
        var timer = try Timer.start();
        for (0..iterations) |_| {
            // ... code to benchmark ...
        }
        time.* = timer.read();
    }

    const stats = Stats.calculate(times);
    return Result{
        .name = "My Benchmark",
        .time_ns = stats.avg,
        .iterations = iterations,
    };
}
```

## Interpreting Results

### Time Measurements
- Reported as nanoseconds per operation (averaged across iterations)
- Multiple samples provide statistical validity
- Warmup runs ensure fair comparison (cache effects, etc.)

### Comparison Format
```
✓ X% faster   - Optimized version is faster
✗ X% slower   - Optimized version is slower
```

### Memory Metrics
- **Allocations**: Number of allocation calls
- **Bytes**: Total bytes allocated
- **Frees**: Number of free calls (for leak detection)

## Benchmark Design Principles

1. **Multiple Scenarios**: Test best-case, typical, and worst-case workloads
2. **Statistical Validity**: Run multiple samples, report avg/min/max/median
3. **Warmup**: Always run warmup iterations to prime caches
4. **Realistic Data**: Use realistic content patterns (not synthetic)
5. **Isolated Testing**: Each benchmark tests one optimization boundary

## Performance Recommendations

### SIMD Vectorization
**Recommendation**: ❌ Rejected for HTML escaping
- Benchmarking showed 0-22% slower than scalar across all test cases
- Setup overhead and two-pass nature prevent effective vectorization
- Sparse special characters mean most SIMD comparisons are wasted
- Scalar implementation is already optimal for this workload

### Packed Structs
**Recommendation**: ⚠️ Not applicable for optional slices
- Cannot pack optional slices (no guaranteed memory representation)
- Regular structs provide best performance
- Focus on layout optimizations instead

### Tag Cache
**Recommendation**: ✅ Current perfect hash is optimal
- O(1) lookup for common tags
- Comptime generation = zero runtime cost
- Consider expanding cache if profiling shows cache misses

### Buffer Strategies
**Recommendation**: ✅ Use pre-allocation when size is known
- Reduces allocations by 50-80%
- Minimal memory waste with accurate estimates
- Consider size estimation heuristics for templates

## Hardware Considerations

Benchmarks run on the actual deployment hardware (M1/M2 Mac). Results may vary on:
- Different CPU architectures (x86_64, ARM, RISC-V)
- Different cache sizes and hierarchies
- Different memory subsystems

Always profile on production hardware for accurate results.

## Adding New Benchmarks

1. Create new file in `src/benchmarks/your_benchmark.zig`
2. Implement `pub fn run(allocator: std.mem.Allocator, writer: anytype) !void`
3. Use common utilities from `root.zig`
4. Add to `root.zig`:
   - Export: `pub const your_benchmark = @import("your_benchmark.zig");`
   - Add to `runByName()` switch
   - Add to `runAll()` sequence
5. Update this README with usage and findings

## Testing

Run benchmark tests:
```bash
zig build test
```

Benchmark files include unit tests to verify correctness of implementations.

## Performance Tips

### General
- Always run warmup iterations
- Use multiple samples for statistical validity
- Test on actual deployment hardware
- Profile before optimizing

### Zig-Specific
- Use `inline` for hot path functions
- Leverage comptime for zero-cost abstractions
- @memcpy for bulk memory operations
- ArrayList with capacity estimation reduces reallocations

## License

Same as parent project.
