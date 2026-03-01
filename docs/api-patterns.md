# API Patterns

ztl provides two implementation patterns for different use cases:

## `ztl.zig` - Explicit ElementOpts Pattern

**When to use**: Complex templates with many nested elements, when self-documenting code is a priority, or when working in a team setting.

**Characteristics**:
- Uses `ElementOpts` struct with named `.props`, `.children`, and `.content` fields
- Slightly more verbose but clearer intent
- Better for complex nested structures
- Supports ergonomic text content via `.content` union
- Benchmark: ~2,248ns per render on M1 Max

**Example**:
```zig
const ztl = @import("ztl");
var z = ztl.Builder.init(alloc);
defer z.deinit();

// Ergonomic text content
try z.h1(.{ .content = .{ .text = "Hello World" } })

// With props and text
try z.div(.{
    .props = .{ .class = "container" },
    .content = .{ .text = "Simple text" },
})

// Multiple elements (traditional)
try z.div(.{
    .props = .{ .class = "container" },
    .children = &[_]El{
        try z.h1(.{ .content = .{ .text = "Title" } }),
        try z.p(.{ .content = .{ .text = "Paragraph" } }),
    },
})
```

## `ztlc.zig` - Direct Parameters Pattern

**When to use**: Performance-critical paths, simpler templates, or when minimizing syntax is important.

**Characteristics**:
- Direct function parameters: `(props, children)`
- More concise, less struct wrapping
- Comptime tag caching for better dynamic performance
- Benchmark: ~2,790ns per render (static), faster for dynamic content

**Example**:
```zig
const ztlc = @import("ztlc");
var z = ztlc.Builder.init(alloc);
defer z.deinit();

try z.div(.{ .class = "container" }, &[_]El{try z.text("Hello")})
```

**Recommendation**: Start with `ztl.zig` for clarity, switch to `ztlc.zig` if profiling shows templating is a bottleneck.
