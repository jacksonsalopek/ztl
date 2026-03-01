const std = @import("std");
const ztl = @import("./ztl.zig");
const ztlc = @import("./ztlc.zig");

// ztl aliases
const El = ztl.Element;
const Props = ztl.Props;

pub fn link(z: *ztl.PanicBuilder, title: []const u8, href: []const u8) El {
    return z.span(.{
        .props = .{ .class = "mx-1" },
        .children = &[_]El{
            z.a(.{
                .props = .{ .href = href, .class = "hover:text-blue-700 hover:underline" },
                .children = &[_]El{z.text(title)},
            }),
        },
    });
}

pub fn testBase(z: *ztl.PanicBuilder, title: El) El {
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
        try z.h1(.{ .class = "title" }, &[_]ztlc.Element{try z.text("Hello World")}),
        try z.div(
            .{ .class = "container", .id = "main" },
            &[_]ztlc.Element{
                try z.p(.{ .class = "intro" }, &[_]ztlc.Element{try z.text("This is a paragraph with some text content.")}),
                try z.a(.{ .href = "https://example.com", .class = "link" }, &[_]ztlc.Element{try z.text("Link to Example")}),
                try z.div(
                    .{ .class = "content" },
                    &[_]ztlc.Element{
                        try z.p(null, &[_]ztlc.Element{try z.text("Some more content here.")}),
                        try z.ul(
                            .{ .class = "list" },
                            &[_]ztlc.Element{
                                try z.li(null, &[_]ztlc.Element{try z.text("Item 1")}),
                                try z.li(null, &[_]ztlc.Element{try z.text("Item 2")}),
                                try z.li(null, &[_]ztlc.Element{try z.text("Item 3")}),
                                try z.li(null, &[_]ztlc.Element{try z.text("Item 4")}),
                                try z.li(null, &[_]ztlc.Element{try z.text("Item 5")}),
                            },
                        ),
                    },
                ),
                try z.div(
                    .{ .class = "footer" },
                    &[_]ztlc.Element{
                        try z.p(null, &[_]ztlc.Element{try z.text("Footer content.")}),
                        try z.a(.{ .href = "#top", .class = "top-link" }, &[_]ztlc.Element{try z.text("Back to top")}),
                    },
                ),
            },
        ),
    };

    const html = try z.html(.{ .lang = "en" }, &children);

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

fn benchmarkPreallocated(z: *ztl.PanicBuilder, allocator: std.mem.Allocator) !void {
    const stdout = std.fs.File.stdout().deprecatedWriter();

    const children = [_]El{
        z.h1(.{ .props = .{ .class = "title" }, .children = &[_]El{ztl.t("Hello World")} }),
        z.div(.{
            .props = .{ .class = "container", .id = "main" },
            .children = &[_]El{
                z.p(.{ .props = .{ .class = "intro" }, .children = &[_]El{ztl.t("This is a paragraph with some text content.")} }),
                z.a(.{ .props = .{ .href = "https://example.com", .class = "link" }, .children = &[_]El{ztl.t("Link to Example")} }),
                z.div(.{
                    .props = .{ .class = "content" },
                    .children = &[_]El{
                        z.p(.{ .children = &[_]El{ztl.t("Some more content here.")} }),
                        z.ul(.{
                            .props = .{ .class = "list" },
                            .children = &[_]El{
                                z.li(.{ .children = &[_]El{ztl.t("Item 1")} }),
                                z.li(.{ .children = &[_]El{ztl.t("Item 2")} }),
                                z.li(.{ .children = &[_]El{ztl.t("Item 3")} }),
                                z.li(.{ .children = &[_]El{ztl.t("Item 4")} }),
                                z.li(.{ .children = &[_]El{ztl.t("Item 5")} }),
                            },
                        }),
                    },
                }),
                z.div(.{
                    .props = .{ .class = "footer" },
                    .children = &[_]El{
                        z.p(.{ .children = &[_]El{ztl.t("Footer content.")} }),
                        z.a(.{ .props = .{ .href = "#top", .class = "top-link" }, .children = &[_]El{ztl.t("Back to top")} }),
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
fn benchmark(z: *ztl.PanicBuilder, allocator: std.mem.Allocator) !void {
    const stdout = std.fs.File.stdout().deprecatedWriter();

    const children = [_]El{
        z.h1(.{ .props = .{ .class = "title" }, .children = &[_]El{ztl.t("Hello World")} }),
        z.div(.{
            .props = .{ .class = "container", .id = "main" },
            .children = &[_]El{
                z.p(.{ .props = .{ .class = "intro" }, .children = &[_]El{ztl.t("This is a paragraph with some text content.")} }),
                z.a(.{ .props = .{ .href = "https://example.com", .class = "link" }, .children = &[_]El{ztl.t("Link to Example")} }),
                z.div(.{
                    .props = .{ .class = "content" },
                    .children = &[_]El{
                        z.p(.{ .children = &[_]El{ztl.t("Some more content here.")} }),
                        z.ul(.{
                            .props = .{ .class = "list" },
                            .children = &[_]El{
                                z.li(.{ .children = &[_]El{ztl.t("Item 1")} }),
                                z.li(.{ .children = &[_]El{ztl.t("Item 2")} }),
                                z.li(.{ .children = &[_]El{ztl.t("Item 3")} }),
                                z.li(.{ .children = &[_]El{ztl.t("Item 4")} }),
                                z.li(.{ .children = &[_]El{ztl.t("Item 5")} }),
                            },
                        }),
                    },
                }),
                z.div(.{
                    .props = .{ .class = "footer" },
                    .children = &[_]El{
                        z.p(.{ .children = &[_]El{ztl.t("Footer content.")} }),
                        z.a(.{ .props = .{ .href = "#top", .class = "top-link" }, .children = &[_]El{ztl.t("Back to top")} }),
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
        var buf = std.ArrayList(u8){};
        try html.render(&buf, allocator, false);
        const html_string = try buf.toOwnedSlice(allocator);
        allocator.free(html_string);
    }

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
    var z = ztl.PanicBuilder.init(alloc);
    defer z.deinit();

    const header = z.head(.{
        .children = &[_]El{
            z.title(.{ .children = &[_]El{ztl.t("Test page")} }),
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
                        .children = &[_]El{ztl.t("test content")},
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
    const rendered_text = try z.renderToString(example, true);
    const end = try std.time.Instant.now();
    defer alloc.free(rendered_text);
    std.debug.print("\n\nrender output:\n{s}\n", .{rendered_text});
    std.debug.print("\nrender time: {d}ns\n", .{end.since(start)});

    std.debug.print("\n=== ZTL Benchmark (manual buffer) ===\n", .{});
    try benchmark(&z, alloc);

    std.debug.print("\n=== ZTL Benchmark (renderToString with pre-allocation) ===\n", .{});
    try benchmarkPreallocated(&z, alloc);

    std.debug.print("\n=== ZTLC Benchmark (renderToString with pre-allocation) ===\n", .{});
    var zc = ztlc.Builder.init(alloc);
    defer zc.deinit();
    try benchmarkZTLC(&zc, alloc);
}

test "basic ztl structure" {
    const alloc = std.testing.allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const markup = try z.html(.{
        .props = .{ .lang = "en-US" },
        .children = &[_]El{
            try z.head(.{}),
            try z.body(.{}),
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

    const markup = try z.html(.{
        .props = .{ .lang = "en-US" },
        .children = &[_]El{
            try z.head(.{}),
            try z.body(.{}),
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

    const markup = try z.p(.{ .children = &[_]El{ztl.t("test")} });

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
        const textEl = try z.p(.{
            .props = .{ .class = "text" },
            .children = &[_]El{try z.text(item)},
        });
        try textElList.append(alloc, textEl);
    }

    // convert children arraylist to owned array
    // cannot defer free as test will segfault
    const children: []El = try textElList.toOwnedSlice(alloc);

    // build markup
    const markup = try z.html(.{
        .props = .{ .lang = "en-US" },
        .children = &[_]El{
            try z.head(.{}),
            try z.body(.{ .children = children }),
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
    var z = ztl.PanicBuilder.init(alloc);
    defer z.deinit();

    const markup = testBase(&z, ztl.t("Apps"));

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

    const checkbox = try z.div(.{
        .children = &[_]El{
            try z.div(.{
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

    const image = try z.img(.{
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

    const elem = try z.div(.{
        .props = .{
            .id = "container",
            .class = "main-content",
        },
        .children = &[_]El{
            try z.p(.{ .children = &[_]El{ztl.t("Hello")} }),
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

test "html escaping - basic entities" {
    const alloc = std.testing.allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const elem = try z.p(.{ .children = &[_]El{ztl.t("<script>alert('xss')</script>")} });

    var buf = std.ArrayList(u8){};
    defer buf.deinit(alloc);
    try elem.render(&buf, alloc, true);
    const html = try buf.toOwnedSlice(alloc);
    defer alloc.free(html);

    try std.testing.expectEqualStrings(
        "<p>&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;</p>",
        html,
    );
}

test "html escaping - all special characters" {
    const alloc = std.testing.allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const elem = try z.div(.{ .children = &[_]El{ztl.t("& < > \" ' test")} });

    var buf = std.ArrayList(u8){};
    defer buf.deinit(alloc);
    try elem.render(&buf, alloc, true);
    const html = try buf.toOwnedSlice(alloc);
    defer alloc.free(html);

    try std.testing.expectEqualStrings(
        "<div>&amp; &lt; &gt; &quot; &#39; test</div>",
        html,
    );
}

test "html escaping - no unnecessary escaping" {
    const alloc = std.testing.allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const elem = try z.p(.{ .children = &[_]El{ztl.t("Normal text with no special chars")} });

    var buf = std.ArrayList(u8){};
    defer buf.deinit(alloc);
    try elem.render(&buf, alloc, true);
    const html = try buf.toOwnedSlice(alloc);
    defer alloc.free(html);

    try std.testing.expectEqualStrings(
        "<p>Normal text with no special chars</p>",
        html,
    );
}

test "unsafeText - no escaping" {
    const alloc = std.testing.allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const elem = try z.div(.{ .children = &[_]El{try z.unsafeText("<em>pre-escaped</em> HTML")} });

    var buf = std.ArrayList(u8){};
    defer buf.deinit(alloc);
    try elem.render(&buf, alloc, true);
    const html = try buf.toOwnedSlice(alloc);
    defer alloc.free(html);

    try std.testing.expectEqualStrings(
        "<div><em>pre-escaped</em> HTML</div>",
        html,
    );
}

test "union content - text variant" {
    const alloc = std.testing.allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const elem = try z.h1(.{ .content = .{ .text = "Hello World" } });

    var buf = std.ArrayList(u8){};
    defer buf.deinit(alloc);
    try elem.render(&buf, alloc, true);
    const html = try buf.toOwnedSlice(alloc);
    defer alloc.free(html);

    try std.testing.expectEqualStrings("<h1>Hello World</h1>", html);
}

test "union content - text with props" {
    const alloc = std.testing.allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const elem = try z.p(.{
        .props = .{ .class = "intro" },
        .content = .{ .text = "Introduction text" },
    });

    var buf = std.ArrayList(u8){};
    defer buf.deinit(alloc);
    try elem.render(&buf, alloc, true);
    const html = try buf.toOwnedSlice(alloc);
    defer alloc.free(html);

    try std.testing.expectEqualStrings(
        "<p class=\"intro\">Introduction text</p>",
        html,
    );
}

test "union content - elements variant" {
    const alloc = std.testing.allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const elem = try z.div(.{
        .content = .{ .elements = &[_]El{
            try z.h1(.{ .content = .{ .text = "Title" } }),
            try z.p(.{ .content = .{ .text = "Content" } }),
        } },
    });

    var buf = std.ArrayList(u8){};
    defer buf.deinit(alloc);
    try elem.render(&buf, alloc, true);
    const html = try buf.toOwnedSlice(alloc);
    defer alloc.free(html);

    try std.testing.expectEqualStrings(
        "<div><h1>Title</h1><p>Content</p></div>",
        html,
    );
}

test "union content - text is escaped" {
    const alloc = std.testing.allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const elem = try z.div(.{ .content = .{ .text = "<script>alert('xss')</script>" } });

    var buf = std.ArrayList(u8){};
    defer buf.deinit(alloc);
    try elem.render(&buf, alloc, true);
    const html = try buf.toOwnedSlice(alloc);
    defer alloc.free(html);

    try std.testing.expectEqualStrings(
        "<div>&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;</div>",
        html,
    );
}

test "union content - nested with escaping" {
    const alloc = std.testing.allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const elem = try z.article(.{
        .props = .{ .class = "post" },
        .content = .{ .elements = &[_]El{
            try z.h2(.{ .content = .{ .text = "Post Title & More" } }),
            try z.p(.{ .content = .{ .text = "Content with <tags>" } }),
        } },
    });

    var buf = std.ArrayList(u8){};
    defer buf.deinit(alloc);
    try elem.render(&buf, alloc, true);
    const html = try buf.toOwnedSlice(alloc);
    defer alloc.free(html);

    try std.testing.expect(std.mem.indexOf(u8, html, "Post Title &amp; More") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "Content with &lt;tags&gt;") != null);
}

test "new html elements - semantic html5" {
    const alloc = std.testing.allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const page = try z.html(.{
        .children = &[_]El{
            try z.body(.{ .children = &[_]El{
                try z.header(.{ .content = .{ .text = "Header" } }),
                try z.main(.{ .children = &[_]El{
                    try z.article(.{ .children = &[_]El{
                        try z.section(.{ .content = .{ .text = "Section content" } }),
                    } }),
                    try z.aside(.{ .content = .{ .text = "Sidebar" } }),
                } }),
                try z.footer(.{ .content = .{ .text = "Footer" } }),
            } }),
        },
    });

    var buf = std.ArrayList(u8){};
    defer buf.deinit(alloc);
    try page.render(&buf, alloc, true);
    const html = try buf.toOwnedSlice(alloc);
    defer alloc.free(html);

    try std.testing.expect(std.mem.indexOf(u8, html, "<header>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<main>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<article>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<section>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<aside>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<footer>") != null);
}

test "new html elements - form elements" {
    const alloc = std.testing.allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const form = try z.form(.{
        .props = .{ .id = "test-form" },
        .children = &[_]El{
            try z.fieldset(.{ .children = &[_]El{
                try z.legend(.{ .content = .{ .text = "User Info" } }),
                try z.label(.{ .content = .{ .text = "Username:" } }),
                try z.input(.{ .props = .{ .type = "text", .name = "username" } }),
                try z.label(.{ .content = .{ .text = "Bio:" } }),
                try z.textarea(.{ .props = .{ .name = "bio" } }),
                try z.label(.{ .content = .{ .text = "Country:" } }),
                try z.select(.{
                    .props = .{ .name = "country" },
                    .children = &[_]El{
                        try z.option(.{ .props = .{ .value = "us" }, .content = .{ .text = "USA" } }),
                        try z.option(.{ .props = .{ .value = "uk" }, .content = .{ .text = "UK" } }),
                    },
                }),
                try z.button(.{ .props = .{ .type = "submit" }, .content = .{ .text = "Submit" } }),
            } }),
        },
    });

    var buf = std.ArrayList(u8){};
    defer buf.deinit(alloc);
    try form.render(&buf, alloc, true);
    const html = try buf.toOwnedSlice(alloc);
    defer alloc.free(html);

    try std.testing.expect(std.mem.indexOf(u8, html, "<form") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<fieldset>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<legend>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<label>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<input") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<textarea") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<select") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<option") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<button") != null);
}

test "new html elements - text formatting" {
    const alloc = std.testing.allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const content = try z.div(.{ .children = &[_]El{
        try z.pre(.{ .children = &[_]El{
            try z.code(.{ .content = .{ .text = "const x = 42;" } }),
        } }),
        try z.blockquote(.{ .children = &[_]El{
            try z.p(.{ .content = .{ .text = "A famous quote." } }),
            try z.cite(.{ .content = .{ .text = "Author Name" } }),
        } }),
        try z.p(.{ .children = &[_]El{
            ztl.t("Press "),
            try z.kbd(.{ .content = .{ .text = "Ctrl+C" } }),
            ztl.t(" to copy. Output: "),
            try z.samp(.{ .content = .{ .text = "Success!" } }),
        } }),
        try z.figure(.{ .children = &[_]El{
            try z.img(.{ .props = .{ .src = "/image.png", .alt = "Test" } }),
            try z.figcaption(.{ .content = .{ .text = "Image caption" } }),
        } }),
    } });

    var buf = std.ArrayList(u8){};
    defer buf.deinit(alloc);
    try content.render(&buf, alloc, true);
    const html = try buf.toOwnedSlice(alloc);
    defer alloc.free(html);

    try std.testing.expect(std.mem.indexOf(u8, html, "<pre>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<code>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<blockquote>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<cite>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<kbd>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<samp>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<figure>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<figcaption>") != null);
}

test "writer api - basic rendering" {
    const alloc = std.testing.allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const elem = try z.div(.{
        .props = .{ .class = "container" },
        .children = &[_]El{
            try z.h1(.{ .content = .{ .text = "Title" } }),
            try z.p(.{ .content = .{ .text = "Paragraph with <special> chars" } }),
        },
    });

    var buf = std.ArrayList(u8){};
    defer buf.deinit(alloc);
    try elem.renderToWriter(buf.writer(alloc), alloc, true);

    const html = buf.items;
    try std.testing.expect(std.mem.indexOf(u8, html, "<div class=\"container\">") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<h1>Title</h1>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "&lt;special&gt;") != null);
}

test "writer api - streaming to buffer" {
    const alloc = std.testing.allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const page = try z.html(.{
        .props = .{ .lang = "en" },
        .children = &[_]El{
            try z.head(.{ .children = &[_]El{
                try z.title(.{ .content = .{ .text = "Test Page" } }),
            } }),
            try z.body(.{ .children = &[_]El{
                try z.h1(.{ .content = .{ .text = "Hello World" } }),
            } }),
        },
    });

    var buf = std.ArrayList(u8){};
    defer buf.deinit(alloc);
    try page.renderToWriter(buf.writer(alloc), alloc, false);

    const html = buf.items;
    try std.testing.expect(std.mem.indexOf(u8, html, "<!DOCTYPE html>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<html lang=\"en\">") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<title>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "Test Page") != null);
}

test "ztl.t - static text node renders without allocation" {
    const alloc = std.testing.allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const elem = try z.p(.{ .children = &[_]El{ztl.t("Hello, world!")} });

    var buf = std.ArrayList(u8){};
    defer buf.deinit(alloc);
    try elem.render(&buf, alloc, true);
    const html = try buf.toOwnedSlice(alloc);
    defer alloc.free(html);

    try std.testing.expectEqualStrings("<p>Hello, world!</p>", html);
}

test "ztl.t - static text is html-escaped" {
    const alloc = std.testing.allocator;
    var z = ztl.Builder.init(alloc);
    defer z.deinit();

    const elem = try z.div(.{ .children = &[_]El{ztl.t("<b>bold</b> & safe")} });

    var buf = std.ArrayList(u8){};
    defer buf.deinit(alloc);
    try elem.render(&buf, alloc, true);
    const html = try buf.toOwnedSlice(alloc);
    defer alloc.free(html);

    try std.testing.expectEqualStrings("<div>&lt;b&gt;bold&lt;/b&gt; &amp; safe</div>", html);
}

test "ztl.t - getText returns the string" {
    const elem = ztl.t("hello");
    try std.testing.expectEqualStrings("hello", elem.getText().?);
}

test "PanicBuilder - basic rendering without try" {
    const alloc = std.testing.allocator;
    var z = ztl.PanicBuilder.init(alloc);
    defer z.deinit();

    const page = z.html(.{
        .props = .{ .lang = "en-US" },
        .children = &[_]El{
            z.head(.{}),
            z.body(.{
                .children = &[_]El{
                    z.h1(.{ .content = .{ .text = "Hello" } }),
                    z.p(.{ .content = .{ .text = "World" } }),
                },
            }),
        },
    });

    const html = try z.renderToString(page, true);
    defer alloc.free(html);

    try std.testing.expect(std.mem.indexOf(u8, html, "<!DOCTYPE html>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<html lang=\"en-US\">") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<h1>Hello</h1>") != null);
    try std.testing.expect(std.mem.indexOf(u8, html, "<p>World</p>") != null);
}

test "PanicBuilder - with ztl.t() for zero-allocation literals" {
    const alloc = std.testing.allocator;
    var z = ztl.PanicBuilder.init(alloc);
    defer z.deinit();

    const page = z.div(.{
        .props = .{ .class = "container" },
        .children = &[_]El{
            z.h1(.{ .children = &[_]El{ztl.t("Static Title")} }),
            z.p(.{ .children = &[_]El{ztl.t("Static paragraph.")} }),
        },
    });

    const html = try z.renderToString(page, true);
    defer alloc.free(html);

    try std.testing.expectEqualStrings(
        "<div class=\"container\"><h1>Static Title</h1><p>Static paragraph.</p></div>",
        html,
    );
}

test "PanicBuilder - text() for runtime strings" {
    const alloc = std.testing.allocator;
    var z = ztl.PanicBuilder.init(alloc);
    defer z.deinit();

    var buf: [64]u8 = undefined;
    const username = std.fmt.bufPrint(&buf, "User #{d}", .{42}) catch unreachable;

    const elem = z.p(.{ .children = &[_]El{z.text(username)} });
    const html = try z.renderToString(elem, true);
    defer alloc.free(html);

    try std.testing.expectEqualStrings("<p>User #42</p>", html);
}
