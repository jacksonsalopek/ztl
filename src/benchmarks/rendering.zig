//! End-to-end rendering benchmarks for ZTL and ZTLC
//!
//! Tests the complete rendering pipeline including:
//! - Manual buffer management
//! - renderToString convenience method
//! - Size estimation accuracy
//! - Real-world HTML template scenarios

const std = @import("std");
const ztl = @import("ztl");
const ztlc = @import("ztlc");
const bench = @import("root.zig");

/// Build a realistic HTML template for ZTL benchmarking
fn buildTestTemplate(builder: *ztl.Builder) !ztl.Element {
    return try builder.html(.{
        .props = .{ .lang = "en" },
        .children = &[_]ztl.Element{
            try builder.head(.{
                .children = &[_]ztl.Element{
                    try builder.title(.{ .content = .{ .text = "Benchmark Page" } }),
                    try builder.meta(.{ .props = .{ .charset = "UTF-8" } }),
                },
            }),
            try builder.body(.{
                .props = .{ .class = "container" },
                .children = &[_]ztl.Element{
                    try builder.div(.{
                        .props = .{ .class = "header", .id = "main-header" },
                        .children = &[_]ztl.Element{
                            try builder.h1(.{ .content = .{ .text = "Welcome to ZTL" } }),
                            try builder.p(.{ .content = .{ .text = "A fast HTML templating library for Zig" } }),
                        },
                    }),
                    try builder.div(.{
                        .props = .{ .class = "content" },
                        .children = &[_]ztl.Element{
                            try builder.p(.{ .content = .{ .text = "Some <escaped> content with special chars & entities" } }),
                            try builder.ul(.{
                                .children = &[_]ztl.Element{
                                    try builder.li(.{ .content = .{ .text = "Item 1" } }),
                                    try builder.li(.{ .content = .{ .text = "Item 2" } }),
                                    try builder.li(.{ .content = .{ .text = "Item 3" } }),
                                },
                            }),
                        },
                    }),
                },
            }),
        },
    });
}

/// Build a realistic HTML template for ZTLC (different API)
fn buildTestTemplateZTLC(builder: *ztlc.Builder) !ztlc.Element {
    return try builder.html(.{ .lang = "en" }, &[_]ztlc.Element{
        try builder.head(null, &[_]ztlc.Element{
            try builder.title(null, &[_]ztlc.Element{try builder.text("Benchmark Page")}),
            try builder.meta(.{ .charset = "UTF-8" }, null),
        }),
        try builder.body(.{ .class = "container" }, &[_]ztlc.Element{
            try builder.div(.{ .class = "header", .id = "main-header" }, &[_]ztlc.Element{
                try builder.h1(null, &[_]ztlc.Element{try builder.text("Welcome to ZTL")}),
                try builder.p(null, &[_]ztlc.Element{try builder.text("A fast HTML templating library for Zig")}),
            }),
            try builder.div(.{ .class = "content" }, &[_]ztlc.Element{
                try builder.p(null, &[_]ztlc.Element{try builder.text("Some <escaped> content with special chars & entities")}),
                try builder.ul(null, &[_]ztlc.Element{
                    try builder.li(null, &[_]ztlc.Element{try builder.text("Item 1")}),
                    try builder.li(null, &[_]ztlc.Element{try builder.text("Item 2")}),
                    try builder.li(null, &[_]ztlc.Element{try builder.text("Item 3")}),
                }),
            }),
        }),
    });
}

pub fn run(allocator: std.mem.Allocator, writer: anytype) !void {
    try writer.print("\n", .{});
    try writer.print("=" ** 70, .{});
    try writer.print("\n", .{});
    try writer.print("End-to-End Rendering Benchmark\n", .{});
    try writer.print("=" ** 70, .{});
    try writer.print("\n\n", .{});

    const iterations: usize = 10000;

    // ZTL Manual Buffer (using direct render call)
    {
        try writer.print("ZTL Manual Buffer Management:\n", .{});
        try writer.print("-" ** 70, .{});
        try writer.print("\n", .{});

        var timer = try bench.Timer.start();
        var total_time: u64 = 0;

        for (0..iterations) |_| {
            var builder = ztl.Builder.init(allocator);
            defer builder.deinit();

            const element = try buildTestTemplate(&builder);

            timer.reset();
            var buf = std.ArrayList(u8){};
            defer buf.deinit(allocator);
            try element.render(&buf, allocator, true);
            total_time += timer.read();
        }

        const result = bench.Result{
            .name = "ZTL Manual Buffer",
            .time_ns = total_time,
            .iterations = iterations,
        };
        try result.print(writer);

        const time_per_iter = total_time / iterations;
        const rps = @as(f64, 1_000_000_000.0) / @as(f64, @floatFromInt(time_per_iter));
        try writer.print("    Throughput: {d:.0} RPS\n", .{rps});
        try writer.print("\n", .{});
    }

    // ZTL renderToString
    {
        try writer.print("ZTL renderToString():\n", .{});
        try writer.print("-" ** 70, .{});
        try writer.print("\n", .{});

        var timer = try bench.Timer.start();
        var total_time: u64 = 0;

        for (0..iterations) |_| {
            var builder = ztl.Builder.init(allocator);
            defer builder.deinit();

            const element = try buildTestTemplate(&builder);

            timer.reset();
            const html = try builder.renderToString(element, true);
            defer allocator.free(html);
            total_time += timer.read();
        }

        const result = bench.Result{
            .name = "ZTL renderToString",
            .time_ns = total_time,
            .iterations = iterations,
        };
        try result.print(writer);

        const time_per_iter = total_time / iterations;
        const rps = @as(f64, 1_000_000_000.0) / @as(f64, @floatFromInt(time_per_iter));
        try writer.print("    Throughput: {d:.0} RPS\n", .{rps});
        try writer.print("\n", .{});
    }

    // ZTLC renderToString
    {
        try writer.print("ZTLC renderToString():\n", .{});
        try writer.print("-" ** 70, .{});
        try writer.print("\n", .{});

        var timer = try bench.Timer.start();
        var total_time: u64 = 0;

        for (0..iterations) |_| {
            var builder = ztlc.Builder.init(allocator);
            defer builder.deinit();

            const element = try buildTestTemplateZTLC(&builder);

            timer.reset();
            const html = try builder.renderToString(element, true);
            defer allocator.free(html);
            total_time += timer.read();
        }

        const result = bench.Result{
            .name = "ZTLC renderToString",
            .time_ns = total_time,
            .iterations = iterations,
        };
        try result.print(writer);

        const time_per_iter = total_time / iterations;
        const rps = @as(f64, 1_000_000_000.0) / @as(f64, @floatFromInt(time_per_iter));
        try writer.print("    Throughput: {d:.0} RPS\n", .{rps});
        try writer.print("\n", .{});
    }

    try writer.print("=" ** 70, .{});
    try writer.print("\n", .{});
    try writer.print("Recommendations:\n", .{});
    try writer.print("  • Target: 100-150k RPS (7-10μs per render)\n", .{});
    try writer.print("  • Inline hints reduce function call overhead\n", .{});
    try writer.print("  • Improved size estimation reduces reallocations\n", .{});
    try writer.print("=" ** 70, .{});
    try writer.print("\n", .{});
}
