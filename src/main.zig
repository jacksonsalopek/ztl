const std = @import("std");
const ztl = @import("./ztl.zig");
const ztlc = @import("./ztlc.zig");

// ztl aliases
const El = ztl.El;
const Props = ztl.Props;

pub fn link(z: *ztl.ZTLBuilder, title: []const u8, href: []const u8) El {
    return z.span(Props{ .class = "mx-1" }, &[_]El{
        z.a(Props{ .href = href, .class = "hover:text-blue-700 hover:underline" }, &[_]El{
            z.text(title),
        }).el(),
    }).el();
}

pub fn testBase(z: *ztl.ZTLBuilder, title: El) ztl.BaseTag {
    return z.html(Props{
        .lang = "en-US",
    }, &[_]El{
        z.head(null, &[_]El{z.title(null, &[_]El{title}).el()}).el(),
        z.body(null, null).el(),
    });
}

fn benchmark(builder: *ztlc.ZTLBuilder, allocator: std.mem.Allocator) !void {
    const stdout = std.io.getStdOut().writer();

    // Create a more complex sample template that's closer to real-world usage
    const children = [_]ztlc.El{
        builder.h1(.{ .class = "title" }, &[_]ztlc.El{builder.text("Hello World")}).el(),
        builder.div(
            .{ .class = "container", .id = "main" },
            &[_]ztlc.El{
                builder.p(.{ .class = "intro" }, &[_]ztlc.El{builder.text("This is a paragraph with some text content.")}).el(),
                builder.a(.{ .href = "https://example.com", .class = "link" }, &[_]ztlc.El{builder.text("Link to Example")}).el(),
                builder.div(
                    .{ .class = "content" },
                    &[_]ztlc.El{
                        builder.p(null, &[_]ztlc.El{builder.text("Some more content here.")}).el(),
                        builder.ul(
                            .{ .class = "list" },
                            &[_]ztlc.El{
                                builder.li(null, &[_]ztlc.El{builder.text("Item 1")}).el(),
                                builder.li(null, &[_]ztlc.El{builder.text("Item 2")}).el(),
                                builder.li(null, &[_]ztlc.El{builder.text("Item 3")}).el(),
                                builder.li(null, &[_]ztlc.El{builder.text("Item 4")}).el(),
                                builder.li(null, &[_]ztlc.El{builder.text("Item 5")}).el(),
                            },
                        ).el(),
                    },
                ).el(),
                builder.div(
                    .{ .class = "footer" },
                    &[_]ztlc.El{
                        builder.p(null, &[_]ztlc.El{builder.text("Footer content.")}).el(),
                        builder.a(.{ .href = "#top", .class = "top-link" }, &[_]ztlc.El{builder.text("Back to top")}).el(),
                    },
                ).el(),
            },
        ).el(),
    };

    const html = builder.html(.{ .lang = "en" }, &children).el();

    // Setup timing
    var timer = try std.time.Timer.start();
    const iterations: usize = 10000; // More iterations for better average
    var total_ns: u64 = 0;

    // Warmup (to ensure fair comparison)
    for (0..100) |_| {
        const html_string = try builder.renderToString(html, false);
        allocator.free(html_string);
    }

    // Run the benchmark
    for (0..iterations) |_| {
        timer.reset();
        const html_string = try builder.renderToString(html, false);
        defer allocator.free(html_string);
        total_ns += timer.read();
    }

    const average_ns = total_ns / iterations;
    try stdout.print("Average render time: {d}ns\n", .{average_ns});

    // Memory usage benchmark
    const before = std.heap.page_allocator.alloc_count;
    const html_string = try builder.renderToString(html, false);
    allocator.free(html_string);
    const after = std.heap.page_allocator.alloc_count;

    try stdout.print("Memory allocations during render: {d}\n", .{after - before});
}

pub fn main() !void {
    std.debug.print("Running ztl example...\n", .{});
    const alloc = std.heap.page_allocator;
    var z = ztl.ZTLBuilder.init(alloc);
    defer z.deinit();

    const header = z.head(null, &[_]El{
        z.title(null, &[_]El{
            z.text("Test page"),
        }).el(),
    }).el();
    const example = z.html(Props{
        .lang = "en-US",
        // children array must be passed as pointer
    }, &[_]El{
        // props are first arg, children second
        // must pass null if element has no props/children
        // must also call make, which standardizes element structs
        header,
        z.body(Props{
            .class = "body",
        }, &[_]El{
            z.div(Props{
                .id = "app",
                .class = "test",
            }, &[_]El{
                z.text("test content"),
            }).el(),
        }).el(),
    });
    std.debug.print("example.type=\"{any}\"\n", .{@TypeOf(example)});
    std.debug.print("example.lang=\"{?s}\"\n", .{
        example.props.?.lang,
    });
    std.debug.print("example.children[0].tag=\"{?s}\"\n", .{
        example.children.?[0].base.tag,
    });
    std.debug.print("example.children[1].tag=\"{?s}\"\n", .{
        example.children.?[1].base.tag,
    });
    std.debug.print("example.children[1].children[0].tag=\"{?s}\"\n", .{
        example.children.?[1].base.children.?[0].base.tag,
    });
    std.debug.print("example.children[1].children[0].id=\"{?s}\"\n", .{
        example.children.?[1].base.children.?[0].base.props.?.id,
    });
    std.debug.print("example.children[1].children[0].class=\"{?s}\"\n", .{
        example.children.?[1].base.children.?[0].base.props.?.class,
    });
    std.debug.print("example.children[1].children[0].children[0].text=\"{?s}\"\n", .{
        example.children.?[1].base.children.?[0].base.children.?[0].text,
    });

    const start = try std.time.Instant.now();

    var buf = std.ArrayList(u8).init(alloc);
    defer buf.deinit();
    try example.render(&buf, true);
    const rendered_text = try buf.toOwnedSlice();
    const end = try std.time.Instant.now();
    std.debug.print("\n\nrender output:\n{s}\n", .{rendered_text});
    std.debug.print("\nrender time: {d}ns\n", .{end.since(start)});

    var zc = ztlc.ZTLBuilder.init(alloc);
    defer zc.deinit();
    try benchmark(&zc, alloc);
}

test "basic ztl structure" {
    const alloc = std.testing.allocator;
    var z = ztl.ZTLBuilder.init(alloc);
    defer z.deinit();

    const markup = z.html(Props{
        .lang = "en-US",
    }, &[_]El{
        z.head(null, null).el(),
        z.body(null, null).el(),
    });

    if (markup.props) |props| {
        if (props.lang) |lang| try std.testing.expectEqualStrings("en-US", lang);
    }
    try std.testing.expectEqualStrings("head", markup.children.?[0].base.tag);
    try std.testing.expectEqualStrings("body", markup.children.?[1].base.tag);
}

test "basic render" {
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

test "html partial render" {
    const alloc = std.testing.allocator;
    var z = ztl.ZTLBuilder.init(alloc);
    defer z.deinit();

    const markup = z.p(null, &[_]El{z.text("test")});

    var buf = std.ArrayList(u8).init(alloc);
    defer buf.deinit();

    try markup.render(&buf, true);
    const renderedText = try buf.toOwnedSlice();
    try std.testing.expectEqualStrings("<p>test</p>", renderedText);
    alloc.free(renderedText);
}

// @TODO: figure out more performant way to iterate
test "dynamic render" {
    // init allocator, ArenaAllocator is recommended in actual usage
    const alloc = std.testing.allocator;
    var z = ztl.ZTLBuilder.init(alloc);
    defer z.deinit();

    // build list of strings, defer freeing of string memory to end of scope
    var strList = std.ArrayList([]u8).init(alloc);
    defer {
        for (strList.items) |item| {
            alloc.free(item);
        }
        strList.deinit();
    }

    // build strings dynamically, could be from the result of a query as well
    for (1..4) |i| {
        const str = try std.fmt.allocPrint(alloc, "Hi from Text {d}", .{i});
        try strList.append(str);
    }

    // build elements arraylist
    var textElList = std.ArrayList(El).init(alloc);
    defer textElList.deinit();

    // add strings as p tags to elements arraylist
    for (strList.items) |item| {
        const textEl = z.p(Props{
            .class = "text",
        }, &[_]El{z.text(item)}).el();
        try textElList.append(textEl);
    }

    // convert children arraylist to owned array
    // cannot defer free as test will segfault
    const children: []El = try textElList.toOwnedSlice();

    // build markup
    var markup = z.html(Props{
        .lang = "en-US",
    }, &[_]El{
        z.head(null, null).el(),
        z.body(null, children).el(),
    });

    // create buffer to hold element strings as they're rendered
    var buf = std.ArrayList(u8).init(alloc);
    defer buf.deinit();

    const start = try std.time.Instant.now();

    // render markup and convert to string array
    try markup.render(&buf, false);
    const renderedText = try buf.toOwnedSlice();
    const end = try std.time.Instant.now();

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html lang="en-US">
        \\<head>
        \\</head>
        \\<body>
        \\<p class="text">
        \\Hi from Text 1</p>
        \\<p class="text">
        \\Hi from Text 2</p>
        \\<p class="text">
        \\Hi from Text 3</p>
        \\</body>
        \\</html>
        \\
    , renderedText);
    std.debug.print("\nrender time: {d}ns\n", .{end.since(start)});

    // must free allocator at end of scope instead of deferring
    alloc.free(renderedText);
    alloc.free(children);
}

test "layout + component structure" {
    const alloc = std.testing.allocator;
    var z = ztl.ZTLBuilder.init(alloc);
    defer z.deinit();

    const page_title = z.text("Apps");
    var markup = testBase(&z, page_title);

    var buf = std.ArrayList(u8).init(alloc);
    defer buf.deinit();
    try markup.render(&buf, false);
    const rendered_output = try buf.toOwnedSlice();

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html lang="en-US">
        \\<head>
        \\<title>
        \\Apps</title>
        \\</head>
        \\<body>
        \\</body>
        \\</html>
        \\
    , rendered_output);

    alloc.free(rendered_output);
}
