const std = @import("std");
const ztl = @import("./ztl.zig");

// ztl aliases
const html = ztl.html;
const head = ztl.head;
const body = ztl.body;
const p = ztl.p;
const El = ztl.El;
const Props = ztl.Props;
const Text = ztl.Text;

pub fn main() !void {
    std.debug.print("Running ztl example...\n", .{});
    const example = ztl.example;
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
