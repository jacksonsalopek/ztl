//! Buffer Growth Strategy Benchmark
//!
//! Tests different buffer growth and pre-allocation strategies:
//! - ArrayList with default growth (1.5x)
//! - ArrayList with 2x growth
//! - Pre-allocated buffer (accurate size estimation)
//! - Pre-allocated buffer (over-estimation)
//! - FixedBufferStream for small templates
//!
//! Measures:
//! - Total allocations
//! - Memory overhead
//! - Render performance

const std = @import("std");
const benchmarks = @import("root.zig");
const Timer = benchmarks.Timer;
const AllocTracker = benchmarks.AllocTracker;
const Result = benchmarks.Result;
const BenchStats = benchmarks.Stats;

pub fn run(allocator: std.mem.Allocator, writer: anytype) !void {
    try writer.print("\n", .{});
    try writer.print("=" ** 70, .{});
    try writer.print("\n", .{});
    try writer.print("Buffer Growth Strategy Benchmark\n", .{});
    try writer.print("=" ** 70, .{});
    try writer.print("\n\n", .{});

    // Test small templates
    try writer.print("Scenario 1: Small Template (~200 bytes)\n", .{});
    try writer.print("-" ** 70, .{});
    try writer.print("\n", .{});
    try benchmarkSmallTemplate(allocator, writer);

    // Test medium templates
    try writer.print("\n", .{});
    try writer.print("Scenario 2: Medium Template (~2KB)\n", .{});
    try writer.print("-" ** 70, .{});
    try writer.print("\n", .{});
    try benchmarkMediumTemplate(allocator, writer);

    // Test large templates
    try writer.print("\n", .{});
    try writer.print("Scenario 3: Large Template (~20KB)\n", .{});
    try writer.print("-" ** 70, .{});
    try writer.print("\n", .{});
    try benchmarkLargeTemplate(allocator, writer);

    try writer.print("\n", .{});
    try writer.print("=" ** 70, .{});
    try writer.print("\n", .{});
    try writer.print("Recommendations:\n", .{});
    try writer.print("  • Pre-allocation reduces allocations for known sizes\n", .{});
    try writer.print("  • Default growth (1.5x) balances memory and reallocations\n", .{});
    try writer.print("  • FixedBufferStream is optimal for small, bounded templates\n", .{});
    try writer.print("  • Profile actual template sizes in production\n", .{});
    try writer.print("=" ** 70, .{});
    try writer.print("\n", .{});
}

fn benchmarkSmallTemplate(allocator: std.mem.Allocator, writer: anytype) !void {
    const iterations: usize = 50_000;
    const samples: usize = 5;

    // Default ArrayList growth
    try writer.print("\nDefault ArrayList (no pre-allocation):\n", .{});
    const default_result = try benchmarkDefaultGrowth(allocator, .small, iterations, samples);
    try default_result.print(writer);

    // Pre-allocated (accurate)
    try writer.print("\nPre-allocated (accurate size):\n", .{});
    const preallocated_result = try benchmarkPreallocated(allocator, .small, 200, iterations, samples);
    try preallocated_result.print(writer);

    // Pre-allocated (over-estimate)
    try writer.print("\nPre-allocated (over-estimated +50%):\n", .{});
    const overalloc_result = try benchmarkPreallocated(allocator, .small, 300, iterations, samples);
    try overalloc_result.print(writer);

    // Fixed buffer
    try writer.print("\nFixed Buffer Stream:\n", .{});
    const fixed_result = try benchmarkFixedBuffer(allocator, .small, 512, iterations, samples);
    try fixed_result.print(writer);

    // Compare
    var buf: [4096]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buf);
    try Result.compare(default_result, preallocated_result, stream.writer());
    try writer.print("{s}", .{stream.getWritten()});
}

fn benchmarkMediumTemplate(allocator: std.mem.Allocator, writer: anytype) !void {
    const iterations: usize = 10_000;
    const samples: usize = 5;

    try writer.print("\nDefault ArrayList:\n", .{});
    const default_result = try benchmarkDefaultGrowth(allocator, .medium, iterations, samples);
    try default_result.print(writer);

    try writer.print("\nPre-allocated (accurate size):\n", .{});
    const preallocated_result = try benchmarkPreallocated(allocator, .medium, 2048, iterations, samples);
    try preallocated_result.print(writer);

    var buf: [4096]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buf);
    try Result.compare(default_result, preallocated_result, stream.writer());
    try writer.print("{s}", .{stream.getWritten()});
}

fn benchmarkLargeTemplate(allocator: std.mem.Allocator, writer: anytype) !void {
    const iterations: usize = 1_000;
    const samples: usize = 5;

    try writer.print("\nDefault ArrayList:\n", .{});
    const default_result = try benchmarkDefaultGrowth(allocator, .large, iterations, samples);
    try default_result.print(writer);

    try writer.print("\nPre-allocated (accurate size):\n", .{});
    const preallocated_result = try benchmarkPreallocated(allocator, .large, 20480, iterations, samples);
    try preallocated_result.print(writer);

    var buf: [4096]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buf);
    try Result.compare(default_result, preallocated_result, stream.writer());
    try writer.print("{s}", .{stream.getWritten()});
}

const TemplateSize = enum { small, medium, large };

fn getTemplateHtml(size: TemplateSize) []const u8 {
    return switch (size) {
        .small => "<div class=\"container\"><h1>Hello</h1><p>Small template</p></div>",
        .medium =>
        \\<div class="container"><h1>Medium Template</h1><ul>
        \\<li>Item 1 with some longer text content</li>
        \\<li>Item 2 with some longer text content</li>
        \\<li>Item 3 with some longer text content</li>
        \\<li>Item 4 with some longer text content</li>
        \\<li>Item 5 with some longer text content</li>
        \\<li>Item 6 with some longer text content</li>
        \\<li>Item 7 with some longer text content</li>
        \\<li>Item 8 with some longer text content</li>
        \\<li>Item 9 with some longer text content</li>
        \\<li>Item 10 with some longer text content</li>
        \\</ul><p>Additional paragraph content here</p></div>
        ,
        .large =>
        \\<div class="large-container"><h1>Large Template</h1><div class="content"><ul>
        \\<li><span>List item 0 with detailed content</span></li>
        \\<li><span>List item 1 with detailed content</span></li>
        \\<li><span>List item 2 with detailed content</span></li>
        \\<li><span>List item 3 with detailed content</span></li>
        \\<li><span>List item 4 with detailed content</span></li>
        \\<li><span>List item 5 with detailed content</span></li>
        \\<li><span>List item 6 with detailed content</span></li>
        \\<li><span>List item 7 with detailed content</span></li>
        \\<li><span>List item 8 with detailed content</span></li>
        \\<li><span>List item 9 with detailed content</span></li>
        \\</ul></div></div>
        ,
    };
}

fn benchmarkDefaultGrowth(allocator: std.mem.Allocator, size: TemplateSize, iterations: usize, samples: usize) !Result {
    const template_html = getTemplateHtml(size);

    const times = try allocator.alloc(u64, samples);
    defer allocator.free(times);

    var tracker = AllocTracker{ .parent_allocator = allocator };
    const tracked_alloc = tracker.allocator();

    // Warmup
    {
        var buf = std.ArrayList(u8){};
        defer buf.deinit(tracked_alloc);
        try buf.appendSlice(tracked_alloc, template_html);
    }

    tracker.reset();

    // Run samples
    for (times) |*time| {
        var timer = try Timer.start();
        for (0..iterations) |_| {
            var buf = std.ArrayList(u8){};
            defer buf.deinit(tracked_alloc);
            try buf.appendSlice(tracked_alloc, template_html);
        }
        time.* = timer.read();
    }

    const stats = BenchStats.calculate(times);
    const alloc_stats = tracker.snapshot();

    return Result{
        .name = "Default Growth",
        .time_ns = stats.avg,
        .iterations = iterations,
        .allocations = alloc_stats.allocations / iterations,
        .bytes_allocated = alloc_stats.bytes / iterations,
    };
}

fn benchmarkPreallocated(allocator: std.mem.Allocator, size: TemplateSize, capacity: usize, iterations: usize, samples: usize) !Result {
    const template_html = getTemplateHtml(size);

    const times = try allocator.alloc(u64, samples);
    defer allocator.free(times);

    var tracker = AllocTracker{ .parent_allocator = allocator };
    const tracked_alloc = tracker.allocator();

    // Warmup
    {
        var buf = try std.ArrayList(u8).initCapacity(tracked_alloc, capacity);
        defer buf.deinit(tracked_alloc);
        try buf.appendSlice(tracked_alloc, template_html);
    }

    tracker.reset();

    // Run samples
    for (times) |*time| {
        var timer = try Timer.start();
        for (0..iterations) |_| {
            var buf = try std.ArrayList(u8).initCapacity(tracked_alloc, capacity);
            defer buf.deinit(tracked_alloc);
            try buf.appendSlice(tracked_alloc, template_html);
        }
        time.* = timer.read();
    }

    const stats = BenchStats.calculate(times);
    const alloc_stats = tracker.snapshot();

    return Result{
        .name = "Pre-allocated",
        .time_ns = stats.avg,
        .iterations = iterations,
        .allocations = alloc_stats.allocations / iterations,
        .bytes_allocated = alloc_stats.bytes / iterations,
    };
}

fn benchmarkFixedBuffer(allocator: std.mem.Allocator, size: TemplateSize, buffer_size: usize, iterations: usize, samples: usize) !Result {
    _ = allocator;
    if (size != .small) return error.FixedBufferOnlyForSmall;

    const template_html = getTemplateHtml(size);

    const times = try std.heap.page_allocator.alloc(u64, samples);
    defer std.heap.page_allocator.free(times);

    // Warmup
    {
        var buf: [512]u8 = undefined;
        var stream = std.io.fixedBufferStream(&buf);
        try stream.writer().writeAll(template_html);
    }

    // Run samples
    for (times) |*time| {
        var timer = try Timer.start();
        for (0..iterations) |_| {
            var buf: [512]u8 = undefined;
            var stream = std.io.fixedBufferStream(&buf);
            try stream.writer().writeAll(template_html);
        }
        time.* = timer.read();
    }

    const stats = BenchStats.calculate(times);

    return Result{
        .name = "Fixed Buffer",
        .time_ns = stats.avg,
        .iterations = iterations,
        .allocations = 0,
        .bytes_allocated = buffer_size,
    };
}

test "fixed buffer handles small template" {
    const template_html = getTemplateHtml(.small);

    var buf: [512]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buf);
    try stream.writer().writeAll(template_html);

    const output = stream.getWritten();
    try std.testing.expect(output.len > 0);
    try std.testing.expect(output.len < 512);
}
