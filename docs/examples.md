# Examples

## Complete Example

```zig
const std = @import("std");
const ztl = @import("ztl");

pub fn main() !void {
    const alloc = std.testing.allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const markup = try z.html(.{
        .props = .{ .lang = "en-US" },
        .children = &[_]ztl.Element{
            try z.head(.{}),
            try z.body(.{
                .children = &[_]ztl.Element{
                    try z.h1(.{ .content = .{ .text = "Welcome" } }),
                    try z.p(.{ .content = .{ .text = "This is a paragraph." } }),
                },
            }),
        },
    });

    var buf = std.ArrayList(u8).init(alloc);
    defer buf.deinit();

    try markup.render(&buf, alloc, false);
    const renderedText = try buf.toOwnedSlice(alloc);
    defer alloc.free(renderedText);
    
    std.debug.print("{s}\n", .{renderedText});
}
```

## More Examples

For additional examples, refer to the tests in `src/main.zig`, which demonstrate:
- Complex nested structures
- Dynamic content generation
- HTMX integration patterns
- ARIA accessibility patterns
- Memory management strategies
- Streaming to files and writers
