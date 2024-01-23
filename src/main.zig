const std = @import("std");
const ztl = @import("./ztl.zig");

// ztl aliases
const html = ztl.html;
const head = ztl.head;
const body = ztl.body;
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
        head(null, null).make(),
        body(null, null).make(),
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
        head(null, null).make(),
        body(null, null).make(),
    });

    const alloc = std.testing.allocator;
    var buf = std.ArrayList(u8).init(alloc);
    defer buf.deinit();

    try markup.render(&buf);
    const renderedText = try buf.toOwnedSlice();
    try std.testing.expectEqualStrings("<html lang=\"en-US\"><head></head><body></body></html>", renderedText);
    alloc.free(renderedText);
}

test "dynamic render" {
    const alloc = std.testing.allocator;
    var textList = std.ArrayList(El).init(alloc);
    defer textList.deinit();

    for (1..4) |i| {
        const str = try std.fmt.allocPrint(alloc, "Hi from Text {d}", .{i});
        const text = Text(str);
        try textList.append(text);
    }

    const children: []El = try textList.toOwnedSlice();

    const markup = html(Props{
        .lang = "en-US",
    }, &[_]El{
        head(null, null).make(),
        body(null, children).make(),
    });

    var buf = std.ArrayList(u8).init(alloc);
    defer buf.deinit();

    try markup.render(&buf);
    const renderedText = try buf.toOwnedSlice();
    try std.testing.expectEqualStrings("<html lang=\"en-US\"><head></head><body>Hi from Text 1Hi from Text 2Hi from Text 3</body></html>", renderedText);
    alloc.free(renderedText);
    alloc.free(children);
}
