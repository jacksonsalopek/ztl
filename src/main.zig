const std = @import("std");
const ztl = @import("./ztl.zig");
const ztlc = @import("./ztlc.zig");

// ztl aliases
const El = ztl.Element;
const Props = ztl.Props;

pub fn link(z: *ztl.Builder, title: []const u8, href: []const u8) El {
    return z.span(.{
        .props = .{ .class = "mx-1" },
        .children = &[_]El{
            z.a(.{
                .props = .{ .href = href, .class = "hover:text-blue-700 hover:underline" },
                .children = &[_]El{
                    z.text(title),
                },
            }),
        },
    });
}

pub fn testBase(z: *ztl.Builder, title: El) El {
    return z.html(.{
        .props = .{ .lang = "en-US" },
        .children = &[_]El{
            z.head(.{ .children = &[_]El{z.title(.{ .children = &[_]El{title} })} }),
            z.body(.{}),
        },
    });
}

// Modified to accept the error union type
fn benchmarkZTLC(z: anytype, allocator: std.mem.Allocator) !void {
    const stdout = std.fs.File.stdout().deprecatedWriter();

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

fn benchmarkPreallocated(z: *ztl.Builder, allocator: std.mem.Allocator) !void {
    const stdout = std.fs.File.stdout().deprecatedWriter();

    const children = [_]El{
        z.h1(.{ .props = .{ .class = "title" }, .children = &[_]El{z.text("Hello World")} }),
        z.div(.{
            .props = .{ .class = "container", .id = "main" },
            .children = &[_]El{
                z.p(.{ .props = .{ .class = "intro" }, .children = &[_]El{z.text("This is a paragraph with some text content.")} }),
                z.a(.{ .props = .{ .href = "https://example.com", .class = "link" }, .children = &[_]El{z.text("Link to Example")} }),
                z.div(.{
                    .props = .{ .class = "content" },
                    .children = &[_]El{
                        z.p(.{ .children = &[_]El{z.text("Some more content here.")} }),
                        z.ul(.{
                            .props = .{ .class = "list" },
                            .children = &[_]El{
                                z.li(.{ .children = &[_]El{z.text("Item 1")} }),
                                z.li(.{ .children = &[_]El{z.text("Item 2")} }),
                                z.li(.{ .children = &[_]El{z.text("Item 3")} }),
                                z.li(.{ .children = &[_]El{z.text("Item 4")} }),
                                z.li(.{ .children = &[_]El{z.text("Item 5")} }),
                            },
                        }),
                    },
                }),
                z.div(.{
                    .props = .{ .class = "footer" },
                    .children = &[_]El{
                        z.p(.{ .children = &[_]El{z.text("Footer content.")} }),
                        z.a(.{ .props = .{ .href = "#top", .class = "top-link" }, .children = &[_]El{z.text("Back to top")} }),
                    },
                }),
            },
        }),
    };

    const html = z.html(.{ .props = .{ .lang = "en" }, .children = &children });

    var timer = try std.time.Timer.start();
    const iterations: usize = 10000;
    var total_ns: u64 = 0;

    for (0..100) |_| {
        const html_string = try z.renderToString(html, false);
        allocator.free(html_string);
    }

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
fn benchmark(z: *ztl.Builder, allocator: std.mem.Allocator) !void {
    const stdout = std.fs.File.stdout().deprecatedWriter();

    // Create a more complex sample template that's closer to real-world usage
    const children = [_]El{
        z.h1(.{ .props = .{ .class = "title" }, .children = &[_]El{z.text("Hello World")} }),
        z.div(.{
            .props = .{ .class = "container", .id = "main" },
            .children = &[_]El{
                z.p(.{ .props = .{ .class = "intro" }, .children = &[_]El{z.text("This is a paragraph with some text content.")} }),
                z.a(.{ .props = .{ .href = "https://example.com", .class = "link" }, .children = &[_]El{z.text("Link to Example")} }),
                z.div(.{
                    .props = .{ .class = "content" },
                    .children = &[_]El{
                        z.p(.{ .children = &[_]El{z.text("Some more content here.")} }),
                        z.ul(.{
                            .props = .{ .class = "list" },
                            .children = &[_]El{
                                z.li(.{ .children = &[_]El{z.text("Item 1")} }),
                                z.li(.{ .children = &[_]El{z.text("Item 2")} }),
                                z.li(.{ .children = &[_]El{z.text("Item 3")} }),
                                z.li(.{ .children = &[_]El{z.text("Item 4")} }),
                                z.li(.{ .children = &[_]El{z.text("Item 5")} }),
                            },
                        }),
                    },
                }),
                z.div(.{
                    .props = .{ .class = "footer" },
                    .children = &[_]El{
                        z.p(.{ .children = &[_]El{z.text("Footer content.")} }),
                        z.a(.{ .props = .{ .href = "#top", .class = "top-link" }, .children = &[_]El{z.text("Back to top")} }),
                    },
                }),
            },
        }),
    };

    const html = z.html(.{ .props = .{ .lang = "en" }, .children = &children });

    // Setup timing
    var timer = try std.time.Timer.start();
    const iterations: usize = 10000; // More iterations for better average
    var total_ns: u64 = 0;

    // Warmup (to ensure fair comparison)
    for (0..100) |_| {
        var buf = std.ArrayList(u8){};
        try html.render(&buf, allocator, false);
        const html_string = try buf.toOwnedSlice(allocator);
        allocator.free(html_string);
    }

    // Run the benchmark
    for (0..iterations) |_| {
        timer.reset();
        var buf = std.ArrayList(u8){};
        try html.render(&buf, allocator, false);
        const html_string = try buf.toOwnedSlice(allocator);
        defer allocator.free(html_string);
        total_ns += timer.read();
    }

    const average_ns = total_ns / iterations;
    try stdout.print("Average render time: {d}ns\n", .{average_ns});
}

pub fn main() !void {
    std.debug.print("Running ztl example...\n", .{});
    const alloc = std.heap.page_allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const header = z.head(.{
        .children = &[_]El{
            z.title(.{ .children = &[_]El{z.text("Test page")} }),
        },
    });
    const example = z.html(.{
        .props = .{ .lang = "en-US" },
        .children = &[_]El{
            header,
            z.body(.{
                .props = .{ .class = "body" },
                .children = &[_]El{
                    z.div(.{
                        .props = .{ .id = "app", .class = "test" },
                        .children = &[_]El{z.text("test content")},
                    }),
                },
            }),
        },
    });
    std.debug.print("example.type=\"{any}\"\n", .{@TypeOf(example)});
    if (example.getProps()) |props| {
        std.debug.print("example.lang=\"{?s}\"\n", .{props.lang});
    }
    if (example.getChild(0)) |head| {
        std.debug.print("example.children[0].tag=\"{?s}\"\n", .{head.getTag()});
    }
    if (example.getChild(1)) |body| {
        std.debug.print("example.children[1].tag=\"{?s}\"\n", .{body.getTag()});
        if (body.getChild(0)) |div| {
            std.debug.print("example.children[1].children[0].tag=\"{?s}\"\n", .{div.getTag()});
            std.debug.print("example.children[1].children[0].id=\"{?s}\"\n", .{div.getId()});
            std.debug.print("example.children[1].children[0].class=\"{?s}\"\n", .{div.getClass()});
            if (div.getChild(0)) |text| {
                std.debug.print("example.children[1].children[0].children[0].text=\"{?s}\"\n", .{text.getText()});
            }
        }
    }

    const start = try std.time.Instant.now();

    var buf = std.ArrayList(u8){};
    defer buf.deinit(alloc);
    try example.render(&buf, alloc, true);
    const rendered_text = try buf.toOwnedSlice(alloc);
    const end = try std.time.Instant.now();
    std.debug.print("\n\nrender output:\n{s}\n", .{rendered_text});
    std.debug.print("\nrender time: {d}ns\n", .{end.since(start)});

    // benchmark initial implementation
    std.debug.print("\n=== ZTL Benchmark (manual buffer) ===\n", .{});
    try benchmark(&z, alloc);

    // benchmark with pre-allocation
    std.debug.print("\n=== ZTL Benchmark (renderToString with pre-allocation) ===\n", .{});
    try benchmarkPreallocated(&z, alloc);

    // Create the Builder and properly handle the error
    std.debug.print("\n=== ZTLC Benchmark (renderToString with pre-allocation) ===\n", .{});
    var zc = try ztlc.Builder.init(alloc);
    defer zc.deinit();

    try benchmarkZTLC(&zc, alloc);
}

test "basic ztl structure" {
    const alloc = std.testing.allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const markup = z.html(.{
        .props = .{ .lang = "en-US" },
        .children = &[_]El{
            z.head(.{}),
            z.body(.{}),
        },
    });

    if (markup.getProps()) |props| {
        if (props.lang) |lang| try std.testing.expectEqualStrings("en-US", lang);
    }
    if (markup.getChild(0)) |head| {
        try std.testing.expectEqualStrings("head", head.getTag().?);
    }
    if (markup.getChild(1)) |body| {
        try std.testing.expectEqualStrings("body", body.getTag().?);
    }
}

test "basic render" {
    const alloc = std.testing.allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const markup = z.html(.{
        .props = .{ .lang = "en-US" },
        .children = &[_]El{
            z.head(.{}),
            z.body(.{}),
        },
    });

    var buf = std.ArrayList(u8){};
    defer buf.deinit(alloc);

    try markup.render(&buf, alloc, true);
    const renderedText = try buf.toOwnedSlice(alloc);
    try std.testing.expectEqualStrings("<!DOCTYPE html><html lang=\"en-US\"><head></head><body></body></html>", renderedText);
    alloc.free(renderedText);
}

test "html partial render" {
    const alloc = std.testing.allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const markup = z.p(.{ .children = &[_]El{z.text("test")} });

    var buf = std.ArrayList(u8){};
    defer buf.deinit(alloc);

    try markup.render(&buf, alloc, true);
    const renderedText = try buf.toOwnedSlice(alloc);
    try std.testing.expectEqualStrings("<p>test</p>", renderedText);
    alloc.free(renderedText);
}

// @TODO: figure out more performant way to iterate
test "dynamic render" {
    // init allocator, ArenaAllocator is recommended in actual usage
    const alloc = std.testing.allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    // build list of strings, defer freeing of string memory to end of scope
    var strList = std.ArrayList([]u8){};
    defer {
        for (strList.items) |item| {
            alloc.free(item);
        }
        strList.deinit(alloc);
    }

    // build strings dynamically, could be from the result of a query as well
    for (1..4) |i| {
        const str = try std.fmt.allocPrint(alloc, "Hi from Text {d}", .{i});
        try strList.append(alloc, str);
    }

    // build elements arraylist
    var textElList = std.ArrayList(El){};
    defer textElList.deinit(alloc);

    // add strings as p tags to elements arraylist
    for (strList.items) |item| {
        const textEl = z.p(.{
            .props = .{ .class = "text" },
            .children = &[_]El{z.text(item)},
        });
        try textElList.append(alloc, textEl);
    }

    // convert children arraylist to owned array
    // cannot defer free as test will segfault
    const children: []El = try textElList.toOwnedSlice(alloc);

    // build markup
    const markup = z.html(.{
        .props = .{ .lang = "en-US" },
        .children = &[_]El{
            z.head(.{}),
            z.body(.{ .children = children }),
        },
    });

    // create buffer to hold element strings as they're rendered
    var buf = std.ArrayList(u8){};
    defer buf.deinit(alloc);

    // render markup and convert to string array
    try markup.render(&buf, alloc, false);
    const renderedText = try buf.toOwnedSlice(alloc);

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
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const page_title = z.text("Apps");
    const markup = testBase(&z, page_title);

    var buf = std.ArrayList(u8){};
    defer buf.deinit(alloc);
    try markup.render(&buf, alloc, false);
    const rendered_output = try buf.toOwnedSlice(alloc);

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

test "strong typed props - boolean attributes" {
    const alloc = std.testing.allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const checkbox = z.div(.{
        .children = &[_]El{
            z.div(.{
                .props = .{
                    .type = "checkbox",
                    .checked = true,
                    .disabled = false,
                },
            }),
        },
    });

    var buf = std.ArrayList(u8){};
    defer buf.deinit(alloc);
    try checkbox.render(&buf, alloc, true);
    const rendered = try buf.toOwnedSlice(alloc);
    defer alloc.free(rendered);

    try std.testing.expect(std.mem.indexOf(u8, rendered, "checked=\"checked\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "disabled") == null);
}

test "strong typed props - numeric attributes" {
    const alloc = std.testing.allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const image = z.img(.{
        .props = .{
            .src = "/test.png",
            .width = 800,
            .height = 600,
            .alt = "Test image",
        },
    });

    var buf = std.ArrayList(u8){};
    defer buf.deinit(alloc);
    try image.render(&buf, alloc, true);
    const rendered = try buf.toOwnedSlice(alloc);
    defer alloc.free(rendered);

    try std.testing.expect(std.mem.indexOf(u8, rendered, "width=\"800\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "height=\"600\"") != null);
}

test "helper methods - accessing element properties" {
    const alloc = std.testing.allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const elem = z.div(.{
        .props = .{
            .id = "container",
            .class = "main-content",
        },
        .children = &[_]El{
            z.p(.{ .children = &[_]El{z.text("Hello")} }),
        },
    });

    try std.testing.expectEqualStrings("div", elem.getTag().?);
    try std.testing.expectEqualStrings("container", elem.getId().?);
    try std.testing.expectEqualStrings("main-content", elem.getClass().?);

    const child = elem.getChild(0).?;
    try std.testing.expectEqualStrings("p", child.getTag().?);

    const text_node = child.getChild(0).?;
    try std.testing.expectEqualStrings("Hello", text_node.getText().?);
}
