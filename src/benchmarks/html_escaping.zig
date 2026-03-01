//! HTML Entity Escaping Benchmark
//!
//! Performance baseline for HTML entity escaping using scalar implementation.
//! SIMD vectorization was tested but rejected due to overhead exceeding benefits.
//!
//! Measures:
//! - Scalar implementation (two-pass: count + write)
//!
//! Tests across:
//! - String sizes: 8, 16, 32, 64, 128, 256, 512, 1024 bytes
//! - Content patterns: no special chars, 10% special chars, 50% special chars
//!
//! ## Why No SIMD?
//! Benchmarking showed SIMD @Vector(16, u8) was 0-22% slower than scalar across
//! all test cases due to setup overhead and two-pass nature of the algorithm.

const std = @import("std");
const benchmarks = @import("root.zig");
const Timer = benchmarks.Timer;
const Result = benchmarks.Result;
const BenchStats = benchmarks.Stats;

// Import html_core directly - it will be in the same source tree
const html_core = struct {
    const Str = []const u8;

    pub inline fn escapeHtmlToBuffer(buf: *std.ArrayList(u8), allocator: std.mem.Allocator, input: []const u8) !void {
        var extra: usize = 0;
        for (input) |c| {
            extra += switch (c) {
                '&' => 4,
                '<' => 3,
                '>' => 3,
                '"' => 5,
                '\'' => 4,
                else => 0,
            };
        }

        if (extra == 0) {
            try buf.appendSlice(allocator, input);
            return;
        }

        try buf.ensureUnusedCapacity(allocator, input.len + extra);

        const start_len = buf.items.len;
        buf.items.len += input.len + extra;

        var dest = buf.items[start_len..];
        var i: usize = 0;
        for (input) |c| {
            switch (c) {
                '&' => {
                    @memcpy(dest[i .. i + 5], "&amp;");
                    i += 5;
                },
                '<' => {
                    @memcpy(dest[i .. i + 4], "&lt;");
                    i += 4;
                },
                '>' => {
                    @memcpy(dest[i .. i + 4], "&gt;");
                    i += 4;
                },
                '"' => {
                    @memcpy(dest[i .. i + 6], "&quot;");
                    i += 6;
                },
                '\'' => {
                    @memcpy(dest[i .. i + 5], "&#39;");
                    i += 5;
                },
                else => {
                    dest[i] = c;
                    i += 1;
                },
            }
        }
    }
};

pub fn run(allocator: std.mem.Allocator, writer: anytype) !void {
    try writer.print("\n", .{});
    try writer.print("=" ** 70, .{});
    try writer.print("\n", .{});
    try writer.print("HTML Entity Escaping Benchmark\n", .{});
    try writer.print("=" ** 70, .{});
    try writer.print("\n\n", .{});

    const sizes = [_]usize{ 0, 8, 16, 32, 64, 128, 256, 512, 1024 };

    // Test 1: Best case - no special characters
    try writer.print("Scenario 1: No Special Characters (Best Case)\n", .{});
    try writer.print("-" ** 70, .{});
    try writer.print("\n", .{});
    for (sizes) |size| {
        if (size == 0) continue;
        try benchmarkNoSpecialChars(allocator, writer, size);
    }

    // Test 2: Typical HTML - 10% special characters
    try writer.print("\n", .{});
    try writer.print("Scenario 2: 10% Special Characters (Typical HTML)\n", .{});
    try writer.print("-" ** 70, .{});
    try writer.print("\n", .{});
    for (sizes) |size| {
        if (size == 0) continue;
        try benchmarkTypicalHtml(allocator, writer, size);
    }

    // Test 3: Worst case - 50% special characters
    try writer.print("\n", .{});
    try writer.print("Scenario 3: 50% Special Characters (Worst Case)\n", .{});
    try writer.print("-" ** 70, .{});
    try writer.print("\n", .{});
    for (sizes) |size| {
        if (size == 0) continue;
        try benchmarkWorstCase(allocator, writer, size);
    }

    try writer.print("\n", .{});
}

fn benchmarkNoSpecialChars(allocator: std.mem.Allocator, writer: anytype, size: usize) !void {
    const test_data = try generateTestString(allocator, size, 0);
    defer allocator.free(test_data);

    try writer.print("\nString size: {d} bytes\n", .{size});

    const iterations: usize = if (size < 128) 100_000 else if (size < 512) 50_000 else 10_000;
    const samples: usize = 5;

    const scalar_result = try benchmarkScalar(allocator, test_data, iterations, samples);
    try scalar_result.print(writer);
}

fn benchmarkTypicalHtml(allocator: std.mem.Allocator, writer: anytype, size: usize) !void {
    const test_data = try generateTestString(allocator, size, 10);
    defer allocator.free(test_data);

    try writer.print("\nString size: {d} bytes (10% special chars)\n", .{size});

    const iterations: usize = if (size < 128) 100_000 else if (size < 512) 50_000 else 10_000;
    const samples: usize = 5;

    const scalar_result = try benchmarkScalar(allocator, test_data, iterations, samples);
    try scalar_result.print(writer);
}

fn benchmarkWorstCase(allocator: std.mem.Allocator, writer: anytype, size: usize) !void {
    const test_data = try generateTestString(allocator, size, 50);
    defer allocator.free(test_data);

    try writer.print("\nString size: {d} bytes (50% special chars)\n", .{size});

    const iterations: usize = if (size < 128) 100_000 else if (size < 512) 50_000 else 10_000;
    const samples: usize = 5;

    const scalar_result = try benchmarkScalar(allocator, test_data, iterations, samples);
    try scalar_result.print(writer);
}

fn benchmarkScalar(allocator: std.mem.Allocator, input: []const u8, iterations: usize, samples: usize) !Result {
    const times = try allocator.alloc(u64, samples);
    defer allocator.free(times);

    // Warmup
    {
        var buf = std.ArrayList(u8){};
        defer buf.deinit(allocator);
        try html_core.escapeHtmlToBuffer(&buf, allocator, input);
    }

    // Run samples
    for (times) |*time| {
        var timer = try Timer.start();
        for (0..iterations) |_| {
            var buf = std.ArrayList(u8){};
            defer buf.deinit(allocator);
            try html_core.escapeHtmlToBuffer(&buf, allocator, input);
        }
        time.* = timer.read();
    }

    const stats = BenchStats.calculate(times);
    return Result{
        .name = "Scalar",
        .time_ns = stats.avg,
        .iterations = iterations,
    };
}

/// Generate test string with specified percentage of special characters
fn generateTestString(allocator: std.mem.Allocator, size: usize, special_percent: usize) ![]u8 {
    const result = try allocator.alloc(u8, size);
    const special_chars = [_]u8{ '&', '<', '>', '"', '\'' };
    const normal_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ";

    var rng = std.Random.DefaultPrng.init(42);
    const random = rng.random();

    for (result, 0..) |*c, i| {
        // Deterministic pattern based on position and percentage
        if ((i * 100) / size < special_percent) {
            c.* = special_chars[random.intRangeAtMost(usize, 0, special_chars.len - 1)];
        } else {
            c.* = normal_chars[random.intRangeAtMost(usize, 0, normal_chars.len - 1)];
        }
    }

    return result;
}

test "scalar escaping correctness" {
    const allocator = std.testing.allocator;

    const input = "<div class=\"test\">Hello & goodbye</div>";
    var buf = std.ArrayList(u8){};
    defer buf.deinit(allocator);

    try html_core.escapeHtmlToBuffer(&buf, allocator, input);

    const expected = "&lt;div class=&quot;test&quot;&gt;Hello &amp; goodbye&lt;/div&gt;";
    try std.testing.expectEqualStrings(expected, buf.items);
}
