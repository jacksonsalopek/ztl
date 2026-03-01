# Benchmarks

Production-ready benchmarks are available in `src/main.zig`, which can be compiled with `zig build -Doptimize=ReleaseFast`.

## Performance Results

On M1 Max (Mac Studio 2022):
```
ztl.zig average render time: 2248ns, TPS: ~444,839
ztlc.zig average render time: 2790ns, TPS: ~358,423
```

## Performance Characteristics

It is expected that the ztlc implementation will outperform the ztl implementation in most cases, but the ztl implementation is still faster in some cases.

- **Static content**: The ztl implementation is faster (as shown in benchmark above)
- **Large dynamic content**: The ztlc implementation is expected to outperform due to comptime tag caching

## Running Benchmarks

```bash
# Build and run benchmarks
zig build -Doptimize=ReleaseFast
./zig-out/bin/ztl
```

## Custom Benchmarks

See `src/benchmarks/` for additional benchmark implementations:
- Buffer growth strategies
- HTML escaping performance
- Rendering patterns
- Struct packing optimization
- Tag cache performance
