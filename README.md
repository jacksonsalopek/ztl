# ztl - Zig Templating Language

Zig HTML templating with no dependencies.

## Features

- **HTML5-compatible** - Standard HTML5 element support
- **Accessible** - First-class ARIA support via `.aria` property
- **HTMX-compatible** - Built-in `.hx` property for HTMX attributes
- **Type-safe** - Strong typing for props (boolean, numeric, string)
- **Secure** - Automatic HTML escaping to prevent XSS
- **Fast** - ~2,200ns average render time (~450K templates/sec)
- **Zero dependencies** - Pure Zig, no external dependencies

## Quick Start

```zig
const std = @import("std");
const ztl = @import("ztl");

pub fn main() !void {
    const alloc = std.testing.allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const page = try z.html(.{
        .props = .{ .lang = "en" },
        .children = &[_]ztl.Element{
            try z.head(.{}),
            try z.body(.{
                .children = &[_]ztl.Element{
                    try z.h1(.{ .content = .{ .text = "Hello, ztl!" } }),
                    try z.p(.{ .content = .{ .text = "Fast, safe HTML templating in Zig." } }),
                },
            }),
        },
    });

    var buf = std.ArrayList(u8).init(alloc);
    defer buf.deinit();

    try page.render(&buf, alloc, false);
    const html = try buf.toOwnedSlice(alloc);
    defer alloc.free(html);
    
    std.debug.print("{s}\n", .{html});
}
```

## Installation

Add ztl to your `build.zig.zon`:

```zig
.dependencies = .{
    .ztl = .{
        .url = "https://github.com/yourusername/ztl/archive/refs/tags/v0.1.0.tar.gz",
        .hash = "...",
    },
},
```

Then in your `build.zig`:

```zig
const ztl = b.dependency("ztl", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("ztl", ztl.module("ztl"));
```

## Documentation

- **[API Patterns](docs/api-patterns.md)** - Choosing between `ztl.zig` and `ztlc.zig`
- **[Usage Guide](docs/usage-guide.md)** - Basic API, text content, typing, helpers, memory
- **[HTMX Support](docs/htmx.md)** - Dynamic content loading and interactions
- **[ARIA Support](docs/aria.md)** - Accessibility features and patterns
- **[Streaming](docs/streaming.md)** - Large template streaming with Writer API
- **[Examples](docs/examples.md)** - Complete usage examples
- **[Benchmarks](docs/benchmarks.md)** - Performance characteristics and testing

## Contributing

Contributions are welcome! Please open an issue or PR.

## License

MIT
