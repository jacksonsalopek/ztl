# ztl - Zig Templating Language

Zig HTML templating with no dependencies.

## Core Features

1. HTML5-compatible
2. Accessible - `.aria` key available on Props
3. HTMX-compatible - `.hx` key available on Props
4. (Relatively) Easy to use.

## Using ztl

All element functions accept an `ElementOpts` struct with optional `props` and `children` fields. This makes the API ergonomic and self-documenting:

```zig
// Element with no props or children
z.div(.{})

// Element with only props
z.div(.{ .props = .{ .class = "container" } })

// Element with only children
z.div(.{ .children = &[_]El{z.text("Hello")} })

// Element with both props and children
z.div(.{
    .props = .{ .class = "container", .id = "main" },
    .children = &[_]El{
        z.h1(.{ .children = &[_]El{z.text("Title")} }),
        z.p(.{ .children = &[_]El{z.text("Paragraph")} }),
    },
})
```

### Strong Typing

Props use appropriate types for better type safety:

```zig
// Boolean attributes (checked, disabled, selected)
z.div(.{ .props = .{ .type = "checkbox", .checked = true, .disabled = false } })
// Renders: <div type="checkbox" checked="checked"></div>
// (disabled=false means the attribute is omitted)

// Numeric attributes (width, height)
z.img(.{ .props = .{ .src = "/image.png", .width = 800, .height = 600 } })
// Renders: <img src="/image.png" width="800" height="600">
```

### Helper Methods

Elements provide convenient methods to access properties without deep optional chaining:

```zig
const elem = z.div(.{
    .props = .{ .id = "container", .class = "main" },
    .children = &[_]El{z.text("Hello")},
});

// Instead of: elem.base.props.?.id
const id = elem.getId(); // Returns ?[]const u8

// Instead of: elem.base.children.?[0]
const child = elem.getChild(0); // Returns ?Element

// Available helpers:
elem.getTag();      // Get tag name
elem.getProps();    // Get props struct
elem.getChildren(); // Get children slice
elem.getChild(i);   // Get child at index
elem.getId();       // Get id attribute
elem.getClass();    // Get class attribute
elem.getText();     // Get text content (if text node)
```

For more examples, refer to the tests in `src/main.zig`.

```zig
const std = @import("std");
const ztl = @import("ztl");

pub fn main() !void {
    const alloc = std.testing.allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const markup = z.html(.{
        .props = .{ .lang = "en-US" },
        .children = &[_]ztl.Element{
            z.head(.{}),
            z.body(.{}),
        },
    });

    var buf = std.ArrayList(u8).init(alloc);
    defer buf.deinit();

    try markup.render(&buf, alloc, true);
    const renderedText = try buf.toOwnedSlice(alloc);
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