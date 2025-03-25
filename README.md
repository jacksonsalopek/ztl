# ztl - Zig Templating Language

Zig HTML templating with no dependencies.

## Core Features

1. HTML5-compatible
2. Accessible - `.aria` key available on Props
3. HTMX-compatible - `.hx` key available on Props
4. (Relatively) Easy to use.

## Using ztl

Section in progress. Please refer to the tests in `src/main.zig` for example usage.

```zig
const std = @import("std");
const ztl = @import("ztl");

pub fn main() !void {
    const alloc = std.testing.allocator;
    var z = ztl.ZTLBuilder.init(alloc);
    defer z.deinit();

    const markup = z.html(Props{
        .lang = "en-US",
    }, &[_]El{
        z.head(null, null).el(),
        z.body(null, null).el(),
    });

    var buf = std.ArrayList(u8).init(alloc);
    defer buf.deinit();

    try markup.render(&buf, true);
    const renderedText = try buf.toOwnedSlice();
    try std.testing.expectEqualStrings("<!DOCTYPE html><html lang=\"en-US\"><head></head><body></body></html>", renderedText);
    alloc.free(renderedText);
}
```

## Benchmarks

Production-ready benchmarks are available in `src/main.zig`, which can be compiled with `zig build -Doptimize=ReleaseFast`.

On M1 Max (Mac Studio 2022):
```
ztl.zig average render time: 2248ns, TPS: ~444,839
ztlc.zig average render time: 2790ns, TPS: ~358,423
```

It is expected that the ztlc implementation will outperform the ztl implementation in most cases, but the ztl implementation is still faster in some cases. In static cases, such as the benchmark above, the ztl implementation is faster.
In large dynamic cases, it is expected that the ztlc implementation will outperform the ztl implementation due to comptime tag caching.