# HTMX Support

ztl has first-class support for HTMX attributes via the `.hx` property.

## Dynamic Content Loading

```zig
try z.button(.{
    .props = .{
        .hx = .{
            .get = "/api/data",
            .target = "#content",
            .swap = "innerHTML",
        },
    },
    .content = .{ .text = "Load Data" },
})
```

## Form Submission with HTMX

```zig
try z.form(.{
    .props = .{
        .hx = .{
            .post = "/api/submit",
            .target = "#result",
            .swap = "outerHTML",
        },
    },
    .children = &[_]El{
        try z.input(.{ .props = .{ .type = "text", .name = "username" } }),
        try z.button(.{ .content = .{ .text = "Submit" } }),
    },
})
```

## Delete with Confirmation

```zig
try z.button(.{
    .props = .{
        .class = "danger",
        .hx = .{
            .delete = "/api/item/123",
            .target = "#item-123",
            .swap = "outerHTML",
        },
    },
    .content = .{ .text = "Delete" },
})
```

## Available HTMX Properties

`boost`, `delete`, `encoding`, `get`, `headers`, `params`, `patch`, `pushURL`, `put`, `post`, `select`, `selectOOB`, `swap`, `swapOOB`, `target`, `vals`.
