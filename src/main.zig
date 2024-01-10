const std = @import("std");
const ztl = @import("./ztl.zig");

pub fn main() !void {
    std.debug.print("Running ztl example...\n", .{});
    const example = ztl.example;
    std.debug.print("example.type=\"{any}\"\n", .{@TypeOf(example)});
    std.debug.print("example.lang=\"{?s}\"\n", .{
        example.base.props.?.lang,
    });
    std.debug.print("example.children[0].tag=\"{?s}\"\n", .{
        example.base.children.?[0].base.tag,
    });
    std.debug.print("example.children[1].tag=\"{?s}\"\n", .{
        example.base.children.?[1].base.tag,
    });
    std.debug.print("example.children[1].children[0].tag=\"{?s}\"\n", .{
        example.base.children.?[1].base.children.?[0].base.tag,
    });
    std.debug.print("example.children[1].children[0].id=\"{?s}\"\n", .{
        example.base.children.?[1].base.children.?[0].base.props.?.id,
    });
    std.debug.print("example.children[1].children[0].class=\"{?s}\"\n", .{
        example.base.children.?[1].base.children.?[0].base.props.?.class,
    });
    std.debug.print("example.children[1].children[0].children[0].text=\"{?s}\"\n", .{
        example.base.children.?[1].base.children.?[0].base.children.?[0].text,
    });
    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    // const stdout_file = std.io.getStdOut().writer();
    // var bw = std.io.bufferedWriter(stdout_file);
    // const stdout = bw.writer();

    // try stdout.print("Run `zig build test` to run the tests.\n", .{});

    // try bw.flush(); // don't forget to flush!
}

test "basic ztl structure" {
    const html = ztl.html(ztl.Props{
        .lang = "en-US",
    }, &[_]ztl.El{
        (ztl.head(null, null){}).make(),
        (ztl.body(null, null){}).make(),
    }){};
    if (html.base.props) |props| {
        if (props.lang) |lang| try std.testing.expectEqualStrings("en-US", lang);
    }
    try std.testing.expectEqualStrings("head", html.base.children.?[0].base.tag);
    try std.testing.expectEqualStrings("body", html.base.children.?[1].base.tag);
}
