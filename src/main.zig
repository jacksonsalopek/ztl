const std = @import("std");
const z = @import("./ztl.zig");

// ztl aliases
const html = z.html;
const head = z.head;
const body = z.body;
const p = z.p;
const El = z.El;
const Props = z.Props;
const Text = z.Text;

pub fn link(title: []const u8, href: []const u8) El {
    return z.span(Props{ .class = "mx-1" }, &[_]El{
        z.a(Props{ .href = href, .class = "hover:text-blue-700 hover:underline" }, &[_]El{
            Text(title),
        }).el(),
    }).el();
}

pub fn base(title: El, content: El) z.BaseTag {
    return html(Props{
        .lang = "en-US",
    }, &[_]El{
        head(null, &[_]El{
            z.meta(Props{ .charset = "utf-8" }, null).el(),
            z.meta(Props{
                .name = "viewport",
                .content = "width=device-width, initial-scale=1",
            }, null).el(),
            z.title(null, &[_]El{ Text("Jackson Salopek | "), title }).el(),
            z.script(Props{ .src = "/js/htmx.js" }, null).el(),
            z.script(Props{ .src = "/js/tailwind.js" }, null).el(),
        }).el(),
        body(null, &[_]El{
            z.a(Props{ .href = "/" }, &[_]El{
                z.h1(Props{ .class = "text-2xl" }, &[_]El{Text("Jackson Salopek")}).el(),
            }).el(),
            z.nav(Props{ .class = "text-center" }, &[_]El{
                link("apps", "/apps"),
                link("blog", "/blog"),
                link("resume", "/pdf/resume.pdf"),
            }).el(),
            z.hr(Props{ .class = "mt-2" }, null).el(),
            content,
        }).el(),
    });
}

pub fn main() !void {
    std.debug.print("Running ztl example...\n", .{});
    const example = z.example;
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
}

test "basic ztl structure" {
    const markup = html(Props{
        .lang = "en-US",
    }, &[_]El{
        head(null, null).el(),
        body(null, null).el(),
    });

    if (markup.props) |props| {
        if (props.lang) |lang| try std.testing.expectEqualStrings("en-US", lang);
    }
    try std.testing.expectEqualStrings("head", markup.children.?[0].base.tag);
    try std.testing.expectEqualStrings("body", markup.children.?[1].base.tag);
}

test "basic render" {
    const markup = html(Props{
        .lang = "en-US",
    }, &[_]El{
        head(null, null).el(),
        body(null, null).el(),
    });

    const alloc = std.testing.allocator;
    var buf = std.ArrayList(u8).init(alloc);
    defer buf.deinit();

    try markup.render(&buf, true);
    const renderedText = try buf.toOwnedSlice();
    try std.testing.expectEqualStrings("<!DOCTYPE html><html lang=\"en-US\"><head></head><body></body></html>", renderedText);
    alloc.free(renderedText);
}

test "html partial render" {
    const markup = p(null, &[_]El{Text("test")});

    const alloc = std.testing.allocator;
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
        const textEl = p(Props{
            .class = "text",
        }, &[_]El{Text(item)}).el();
        try textElList.append(textEl);
    }

    // convert children arraylist to owned array
    // cannot defer free as test will segfault
    const children: []El = try textElList.toOwnedSlice();

    // build markup
    const markup = html(Props{
        .lang = "en-US",
    }, &[_]El{
        head(null, null).el(),
        body(null, children).el(),
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
        \\Hi from Text 3</p>
        \\<p class="text">
        \\Hi from Text 3</p>
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

    const page_title = Text("Apps");
    const markup = base(page_title, z.h1(null, &[_]El{page_title}).el());

    var buf = std.ArrayList(u8).init(alloc);
    defer buf.deinit();
    try markup.render(&buf, false);
    const rendered_output = try buf.toOwnedSlice();

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html lang="en-US">
        \\<head>
        \\</head>
        \\<body>
        \\</body>
        \\</html>
        \\
    , rendered_output);

    alloc.free(rendered_output);
}
