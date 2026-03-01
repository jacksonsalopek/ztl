# Streaming Large Templates

For large templates or network streaming, use the Writer-based API to avoid buffering entire output in memory.

## Basic Streaming

```zig
const file = try std.fs.cwd().createFile("output.html", .{});
defer file.close();

const page = try z.html(.{
    .props = .{ .lang = "en" },
    .children = &[_]El{
        try z.body(.{ .content = .{ .text = "Large content..." } }),
    },
});

// Stream directly to file without buffering entire output
try page.renderToWriter(file.writer(), allocator, false);
```

## Use Cases

This works with any Writer type:
- Files
- Network sockets
- HTTP response bodies
- Custom buffers

## Performance Benefits

The Writer-based API avoids allocating a large buffer, making it ideal for templates that generate hundreds of KB or more of HTML. Instead of building the entire HTML string in memory, content is written incrementally as it's generated.

## Example: HTTP Response

```zig
// With http.zig or similar web framework
fn handler(req: *http.Request, res: *http.Response) !void {
    var z = ztl.Builder.init(req.allocator);
    defer z.deinit();
    
    const page = try z.html(.{
        .props = .{ .lang = "en" },
        .children = &[_]El{
            try z.body(.{ .content = .{ .text = "Content" } }),
        },
    });
    
    // Stream directly to response - no intermediate buffer
    try page.renderToWriter(res.writer(), req.allocator, false);
}
```
