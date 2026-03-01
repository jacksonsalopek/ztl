# Usage Guide

## Basic API

All element functions accept an `ElementOpts` struct with optional `props`, `children`, and `content` fields. This makes the API ergonomic and self-documenting:

```zig
// Element with no props or children
try z.div(.{})

// Element with only props
try z.div(.{ .props = .{ .class = "container" } })

// Element with text content (ergonomic!)
try z.h1(.{ .content = .{ .text = "Hello" } })

// Element with only children (traditional)
try z.div(.{ .children = &[_]El{try z.text("Hello")} })

// Element with both props and children
try z.div(.{
    .props = .{ .class = "container", .id = "main" },
    .children = &[_]El{
        try z.h1(.{ .content = .{ .text = "Title" } }),
        try z.p(.{ .content = .{ .text = "Paragraph" } }),
    },
})
```

## Working with Text Content

Text content is **automatically HTML-escaped** to prevent XSS vulnerabilities:

```zig
// Safe: <, >, &, ", ' are automatically escaped
try z.p(.{ .content = .{ .text = "<script>alert('xss')</script>" } })
// Renders: <p>&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;</p>

// Ergonomic text elements using .content union:
try z.h1(.{ .content = .{ .text = "Page Title" } })

// Multiple elements using .content:
try z.div(.{ .content = .{ .elements = &[_]El{
    try z.h1(.{ .content = .{ .text = "Title" } }),
    try z.p(.{ .content = .{ .text = "Content" } }),
} } })

// Pre-escaped HTML for trusted sources (use sparingly!)
try z.div(.{ .children = &[_]El{try z.unsafeText(markdown_html)} })
```

**Warning**: Only use `unsafeText()` for trusted, pre-escaped content like markdown renderers. Passing user input to `unsafeText()` creates XSS vulnerabilities.

## Strong Typing

Props use appropriate types for better type safety:

```zig
// Boolean attributes (checked, disabled, selected)
try z.div(.{ .props = .{ .type = "checkbox", .checked = true, .disabled = false } })
// Renders: <div type="checkbox" checked="checked"></div>
// (disabled=false means the attribute is omitted)

// Numeric attributes (width, height)
try z.img(.{ .props = .{ .src = "/image.png", .width = 800, .height = 600 } })
// Renders: <img src="/image.png" width="800" height="600">
```

## Helper Methods

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

## Memory Management

The Builder tracks allocations automatically. Call `deinit()` when done:

```zig
var z = ztl.Builder.init(alloc);
defer z.deinit(); // Frees all tracked allocations

// For complex dynamic templates, use ArenaAllocator:
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
defer arena.deinit();
var z = ztl.Builder.init(arena.allocator());
// No need to call z.deinit() - arena handles everything
```

**Note**: Always use `testing.allocator` in tests to detect memory leaks.
