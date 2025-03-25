const std = @import("std");
const ztl = @import("./ztl.zig");
const ztlc = @import("./ztlc.zig");

// ztl aliases
const El = ztl.Element;
const Props = ztl.Props;

pub fn link(z: *ztl.ZTLBuilder, title: []const u8, href: []const u8) El {
    return z.span(Props{ .class = "mx-1" }, &[_]El{
        z.a(Props{ .href = href, .class = "hover:text-blue-700 hover:underline" }, &[_]El{
            z.text(title),
        }),
    });
}

pub fn testBase(z: *ztl.ZTLBuilder, title: El) ztl.BaseTag {
    return z.html(Props{
        .lang = "en-US",
    }, &[_]El{
        z.head(null, &[_]El{z.title(null, &[_]El{title})}),
        z.body(null, null),
    });
}

// Modified to accept the error union type
fn benchmarkZTLC(z: anytype, allocator: std.mem.Allocator) !void {
    const stdout = std.io.getStdOut().writer();

    // Create a more complex sample template that's closer to real-world usage
    const children = [_]ztlc.Element{
        z.h1(.{ .class = "title" }, &[_]ztlc.Element{z.text("Hello World")}),
        z.div(
            .{ .class = "container", .id = "main" },
            &[_]ztlc.Element{
                z.p(.{ .class = "intro" }, &[_]ztlc.Element{z.text("This is a paragraph with some text content.")}),
                z.a(.{ .href = "https://example.com", .class = "link" }, &[_]ztlc.Element{z.text("Link to Example")}),
                z.div(
                    .{ .class = "content" },
                    &[_]ztlc.Element{
                        z.p(null, &[_]ztlc.Element{z.text("Some more content here.")}),
                        z.ul(
                            .{ .class = "list" },
                            &[_]ztlc.Element{
                                z.li(null, &[_]ztlc.Element{z.text("Item 1")}),
                                z.li(null, &[_]ztlc.Element{z.text("Item 2")}),
                                z.li(null, &[_]ztlc.Element{z.text("Item 3")}),
                                z.li(null, &[_]ztlc.Element{z.text("Item 4")}),
                                z.li(null, &[_]ztlc.Element{z.text("Item 5")}),
                            },
                        ),
                    },
                ),
                z.div(
                    .{ .class = "footer" },
                    &[_]ztlc.Element{
                        z.p(null, &[_]ztlc.Element{z.text("Footer content.")}),
                        z.a(.{ .href = "#top", .class = "top-link" }, &[_]ztlc.Element{z.text("Back to top")}),
                    },
                ),
            },
        ),
    };

    const html = z.html(.{ .lang = "en" }, &children);

    // Setup timing
    var timer = try std.time.Timer.start();
    const iterations: usize = 10000; // More iterations for better average
    var total_ns: u64 = 0;

    // Warmup (to ensure fair comparison)
    for (0..100) |_| {
        const html_string = try z.renderToString(html, false);
        allocator.free(html_string);
    }

    // Run the benchmark
    for (0..iterations) |_| {
        timer.reset();
        const html_string = try z.renderToString(html, false);
        defer allocator.free(html_string);
        total_ns += timer.read();
    }

    const average_ns = total_ns / iterations;
    try stdout.print("Average render time: {d}ns\n", .{average_ns});
}

// Benchmark function for ztl.zig
fn benchmark(z: *ztl.ZTLBuilder, allocator: std.mem.Allocator) !void {
    const stdout = std.io.getStdOut().writer();

    // Create a more complex sample template that's closer to real-world usage
    const children = [_]El{
        z.h1(.{ .class = "title" }, &[_]El{z.text("Hello World")}),
        z.div(
            .{ .class = "container", .id = "main" },
            &[_]El{
                z.p(.{ .class = "intro" }, &[_]El{z.text("This is a paragraph with some text content.")}),
                z.a(.{ .href = "https://example.com", .class = "link" }, &[_]El{z.text("Link to Example")}),
                z.div(
                    .{ .class = "content" },
                    &[_]El{
                        z.p(null, &[_]El{z.text("Some more content here.")}),
                        z.ul(
                            ztl.Props{ .class = "list" },
                            &[_]El{
                                z.li(null, &[_]El{z.text("Item 1")}),
                                z.li(null, &[_]El{z.text("Item 2")}),
                                z.li(null, &[_]El{z.text("Item 3")}),
                                z.li(null, &[_]El{z.text("Item 4")}),
                                z.li(null, &[_]El{z.text("Item 5")}),
                            },
                        ),
                    },
                ),
                z.div(
                    .{ .class = "footer" },
                    &[_]El{
                        z.p(null, &[_]El{z.text("Footer content.")}),
                        z.a(.{ .href = "#top", .class = "top-link" }, &[_]El{z.text("Back to top")}),
                    },
                ),
            },
        ),
    };

    const html = z.html(.{ .lang = "en" }, &children);

    // Setup timing
    var timer = try std.time.Timer.start();
    const iterations: usize = 10000; // More iterations for better average
    var total_ns: u64 = 0;

    // Warmup (to ensure fair comparison)
    for (0..100) |_| {
        var buf = std.ArrayList(u8).init(allocator);
        try html.render(&buf, false);
        const html_string = try buf.toOwnedSlice();
        allocator.free(html_string);
    }

    // Run the benchmark
    for (0..iterations) |_| {
        timer.reset();
        var buf = std.ArrayList(u8).init(allocator);
        try html.render(&buf, false);
        const html_string = try buf.toOwnedSlice();
        defer allocator.free(html_string);
        total_ns += timer.read();
    }

    const average_ns = total_ns / iterations;
    try stdout.print("Average render time: {d}ns\n", .{average_ns});
}

pub fn main() !void {
    std.debug.print("Running ztl example...\n", .{});
    const alloc = std.heap.page_allocator;
    var z = ztl.ZTLBuilder.init(alloc);
    defer z.deinit();

    const header = z.head(null, &[_]El{
        z.title(null, &[_]El{
            z.text("Test page"),
        }),
    });
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
            }),
        }),
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

    // benchmark initial implementation
    try benchmark(&z, alloc);

    // Create the ZTLBuilder and properly handle the error
    var zc = try ztlc.ZTLBuilder.init(alloc);
    defer zc.deinit();

    // Now this will work fine
    try benchmarkZTLC(&zc, alloc);
}

test "basic ztl structure" {
    const alloc = std.testing.allocator;
    var z = ztl.ZTLBuilder.init(alloc);
    defer z.deinit();

    const markup = z.html(Props{
        .lang = "en-US",
    }, &[_]El{
        z.head(null, null),
        z.body(null, null),
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
        z.head(null, null),
        z.body(null, null),
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
        const textEl = z.p(.{
            .class = "text",
        }, &[_]El{z.text(item)});
        try textElList.append(textEl);
    }

    // convert children arraylist to owned array
    // cannot defer free as test will segfault
    const children: []El = try textElList.toOwnedSlice();

    // build markup
    var markup = z.html(.{
        .lang = "en-US",
    }, &[_]El{
        z.head(null, null),
        z.body(null, children),
    });

    // create buffer to hold element strings as they're rendered
    var buf = std.ArrayList(u8).init(alloc);
    defer buf.deinit();

    // render markup and convert to string array
    try markup.render(&buf, false);
    const renderedText = try buf.toOwnedSlice();

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
