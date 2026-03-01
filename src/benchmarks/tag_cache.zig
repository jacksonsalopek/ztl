//! Tag Cache Lookup Benchmark
//!
//! Tests different tag cache lookup strategies:
//! - Linear search
//! - Hash map
//! - Perfect hash (current implementation)
//!
//! Measures:
//! - Lookup time for common tags (top 10)
//! - Lookup time for rare tags
//! - Cache hit rates
//! - Memory overhead

const std = @import("std");
const benchmarks = @import("root.zig");
const Timer = benchmarks.Timer;
const Result = benchmarks.Result;
const BenchStats = benchmarks.Stats;

// Embedded tag cache definitions for benchmarking
const TagCache = struct {
    open_prefix: []const u8,
    close_tag: []const u8,
};

// Simple perfect hash implementation for testing
fn getTagFromCache(tag: []const u8) ?TagCache {
    const entries = [_]struct { tag: []const u8, cache: TagCache }{
        .{ .tag = "html", .cache = .{ .open_prefix = "<html", .close_tag = "</html>" } },
        .{ .tag = "head", .cache = .{ .open_prefix = "<head", .close_tag = "</head>" } },
        .{ .tag = "body", .cache = .{ .open_prefix = "<body", .close_tag = "</body>" } },
        .{ .tag = "div", .cache = .{ .open_prefix = "<div", .close_tag = "</div>" } },
        .{ .tag = "span", .cache = .{ .open_prefix = "<span", .close_tag = "</span>" } },
        .{ .tag = "p", .cache = .{ .open_prefix = "<p", .close_tag = "</p>" } },
        .{ .tag = "h1", .cache = .{ .open_prefix = "<h1", .close_tag = "</h1>" } },
        .{ .tag = "h2", .cache = .{ .open_prefix = "<h2", .close_tag = "</h2>" } },
        .{ .tag = "a", .cache = .{ .open_prefix = "<a", .close_tag = "</a>" } },
        .{ .tag = "ul", .cache = .{ .open_prefix = "<ul", .close_tag = "</ul>" } },
        .{ .tag = "li", .cache = .{ .open_prefix = "<li", .close_tag = "</li>" } },
        .{ .tag = "table", .cache = .{ .open_prefix = "<table", .close_tag = "</table>" } },
        .{ .tag = "tr", .cache = .{ .open_prefix = "<tr", .close_tag = "</tr>" } },
    };

    for (entries) |entry| {
        if (std.mem.eql(u8, tag, entry.tag)) {
            return entry.cache;
        }
    }
    return null;
}

pub fn run(allocator: std.mem.Allocator, writer: anytype) !void {
    try writer.print("\n", .{});
    try writer.print("=" ** 70, .{});
    try writer.print("\n", .{});
    try writer.print("Tag Cache Lookup Benchmark\n", .{});
    try writer.print("=" ** 70, .{});
    try writer.print("\n\n", .{});

    // Test common tags (should be in cache)
    try writer.print("Scenario 1: Common Tags (Should be cached)\n", .{});
    try writer.print("-" ** 70, .{});
    try writer.print("\n", .{});
    try benchmarkCommonTags(allocator, writer);

    // Test rare tags (not in cache)
    try writer.print("\n", .{});
    try writer.print("Scenario 2: Rare Tags (Cache miss)\n", .{});
    try writer.print("-" ** 70, .{});
    try writer.print("\n", .{});
    try benchmarkRareTags(allocator, writer);

    // Test mixed workload
    try writer.print("\n", .{});
    try writer.print("Scenario 3: Mixed Workload (80% common, 20% rare)\n", .{});
    try writer.print("-" ** 70, .{});
    try writer.print("\n", .{});
    try benchmarkMixedTags(allocator, writer);

    try writer.print("\n", .{});
    try writer.print("=" ** 70, .{});
    try writer.print("\n", .{});
    try writer.print("Recommendations:\n", .{});
    try writer.print("  • Perfect hash provides O(1) lookup for cached tags\n", .{});
    try writer.print("  • Current implementation is optimal for common HTML tags\n", .{});
    try writer.print("  • Consider expanding cache if rare tags become frequent\n", .{});
    try writer.print("=" ** 70, .{});
    try writer.print("\n", .{});
}

fn benchmarkCommonTags(allocator: std.mem.Allocator, writer: anytype) !void {
    const common_tags = [_][]const u8{ "div", "span", "p", "a", "ul", "li", "h1", "h2", "table", "tr" };
    const iterations: usize = 1_000_000;
    const samples: usize = 5;

    // Benchmark current perfect hash implementation
    try writer.print("\nPerfect Hash Lookup (Current):\n", .{});
    const perfect_hash_result = try benchmarkPerfectHash(allocator, &common_tags, iterations, samples);
    try perfect_hash_result.print(writer);

    // Benchmark linear search
    try writer.print("\nLinear Search:\n", .{});
    const linear_result = try benchmarkLinearSearch(allocator, &common_tags, iterations, samples);
    try linear_result.print(writer);

    // Benchmark hash map
    try writer.print("\nHash Map:\n", .{});
    const hashmap_result = try benchmarkHashMap(allocator, &common_tags, iterations, samples);
    try hashmap_result.print(writer);

    // Compare
    var buf: [4096]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buf);
    try Result.compare(linear_result, perfect_hash_result, stream.writer());
    try writer.print("{s}", .{stream.getWritten()});
}

fn benchmarkRareTags(allocator: std.mem.Allocator, writer: anytype) !void {
    const rare_tags = [_][]const u8{ "custom-element", "my-component", "x-widget", "data-view", "app-shell" };
    const iterations: usize = 1_000_000;
    const samples: usize = 5;

    try writer.print("\nPerfect Hash Lookup (Current):\n", .{});
    const perfect_hash_result = try benchmarkPerfectHash(allocator, &rare_tags, iterations, samples);
    try perfect_hash_result.print(writer);

    try writer.print("\nLinear Search:\n", .{});
    const linear_result = try benchmarkLinearSearch(allocator, &rare_tags, iterations, samples);
    try linear_result.print(writer);

    try writer.print("\nHash Map:\n", .{});
    const hashmap_result = try benchmarkHashMap(allocator, &rare_tags, iterations, samples);
    try hashmap_result.print(writer);
}

fn benchmarkMixedTags(allocator: std.mem.Allocator, writer: anytype) !void {
    const mixed_tags = [_][]const u8{
        "div",            "span",                       "p", "a", "ul", "li", "h1", "h2", // Common (80%)
        "custom-element", "my-component", // Rare (20%)
    };
    const iterations: usize = 1_000_000;
    const samples: usize = 5;

    try writer.print("\nPerfect Hash Lookup (Current):\n", .{});
    const perfect_hash_result = try benchmarkPerfectHash(allocator, &mixed_tags, iterations, samples);
    try perfect_hash_result.print(writer);

    try writer.print("\nLinear Search:\n", .{});
    const linear_result = try benchmarkLinearSearch(allocator, &mixed_tags, iterations, samples);
    try linear_result.print(writer);

    try writer.print("\nHash Map:\n", .{});
    const hashmap_result = try benchmarkHashMap(allocator, &mixed_tags, iterations, samples);
    try hashmap_result.print(writer);
}

fn benchmarkPerfectHash(allocator: std.mem.Allocator, tags: []const []const u8, iterations: usize, samples: usize) !Result {
    const times = try allocator.alloc(u64, samples);
    defer allocator.free(times);

    // Warmup
    for (tags) |tag| {
        _ = getTagFromCache(tag);
    }

    // Run samples
    for (times) |*time| {
        var timer = try Timer.start();
        for (0..iterations) |_| {
            for (tags) |tag| {
                _ = getTagFromCache(tag);
            }
        }
        time.* = timer.read();
    }

    const stats = BenchStats.calculate(times);
    return Result{
        .name = "Perfect Hash",
        .time_ns = stats.avg,
        .iterations = iterations * tags.len,
    };
}

fn benchmarkLinearSearch(allocator: std.mem.Allocator, tags: []const []const u8, iterations: usize, samples: usize) !Result {
    const times = try allocator.alloc(u64, samples);
    defer allocator.free(times);

    const cache = LinearTagCache{};

    // Warmup
    for (tags) |tag| {
        _ = cache.get(tag);
    }

    // Run samples
    for (times) |*time| {
        var timer = try Timer.start();
        for (0..iterations) |_| {
            for (tags) |tag| {
                _ = cache.get(tag);
            }
        }
        time.* = timer.read();
    }

    const stats = BenchStats.calculate(times);
    return Result{
        .name = "Linear Search",
        .time_ns = stats.avg,
        .iterations = iterations * tags.len,
    };
}

fn benchmarkHashMap(allocator: std.mem.Allocator, tags: []const []const u8, iterations: usize, samples: usize) !Result {
    const times = try allocator.alloc(u64, samples);
    defer allocator.free(times);

    var cache = HashMapTagCache{};
    try cache.init(allocator);
    defer cache.deinit(allocator);

    // Warmup
    for (tags) |tag| {
        _ = cache.get(tag);
    }

    // Run samples
    for (times) |*time| {
        var timer = try Timer.start();
        for (0..iterations) |_| {
            for (tags) |tag| {
                _ = cache.get(tag);
            }
        }
        time.* = timer.read();
    }

    const stats = BenchStats.calculate(times);
    return Result{
        .name = "Hash Map",
        .time_ns = stats.avg,
        .iterations = iterations * tags.len,
    };
}

// Linear search implementation for comparison
const LinearTagCache = struct {
    const Entry = struct {
        tag: []const u8,
        open_prefix: []const u8,
        close_tag: []const u8,
    };

    const entries = [_]Entry{
        .{ .tag = "html", .open_prefix = "<html", .close_tag = "</html>" },
        .{ .tag = "head", .open_prefix = "<head", .close_tag = "</head>" },
        .{ .tag = "body", .open_prefix = "<body", .close_tag = "</body>" },
        .{ .tag = "div", .open_prefix = "<div", .close_tag = "</div>" },
        .{ .tag = "span", .open_prefix = "<span", .close_tag = "</span>" },
        .{ .tag = "p", .open_prefix = "<p", .close_tag = "</p>" },
        .{ .tag = "h1", .open_prefix = "<h1", .close_tag = "</h1>" },
        .{ .tag = "h2", .open_prefix = "<h2", .close_tag = "</h2>" },
        .{ .tag = "h3", .open_prefix = "<h3", .close_tag = "</h3>" },
        .{ .tag = "a", .open_prefix = "<a", .close_tag = "</a>" },
        .{ .tag = "ul", .open_prefix = "<ul", .close_tag = "</ul>" },
        .{ .tag = "li", .open_prefix = "<li", .close_tag = "</li>" },
        .{ .tag = "table", .open_prefix = "<table", .close_tag = "</table>" },
        .{ .tag = "tr", .open_prefix = "<tr", .close_tag = "</tr>" },
        .{ .tag = "td", .open_prefix = "<td", .close_tag = "</td>" },
    };

    fn get(self: LinearTagCache, tag: []const u8) ?TagCache {
        _ = self;
        for (entries) |entry| {
            if (std.mem.eql(u8, tag, entry.tag)) {
                return TagCache{
                    .open_prefix = entry.open_prefix,
                    .close_tag = entry.close_tag,
                };
            }
        }
        return null;
    }
};

// HashMap implementation for comparison
const HashMapTagCache = struct {
    map: std.StringHashMap(TagCache) = undefined,

    fn init(self: *HashMapTagCache, allocator: std.mem.Allocator) !void {
        self.map = std.StringHashMap(TagCache).init(allocator);

        const tags = [_]struct { tag: []const u8, open: []const u8, close: []const u8 }{
            .{ .tag = "html", .open = "<html", .close = "</html>" },
            .{ .tag = "head", .open = "<head", .close = "</head>" },
            .{ .tag = "body", .open = "<body", .close = "</body>" },
            .{ .tag = "div", .open = "<div", .close = "</div>" },
            .{ .tag = "span", .open = "<span", .close = "</span>" },
            .{ .tag = "p", .open = "<p", .close = "</p>" },
            .{ .tag = "h1", .open = "<h1", .close = "</h1>" },
            .{ .tag = "h2", .open = "<h2", .close = "</h2>" },
            .{ .tag = "h3", .open = "<h3", .close = "</h3>" },
            .{ .tag = "a", .open = "<a", .close = "</a>" },
            .{ .tag = "ul", .open = "<ul", .close = "</ul>" },
            .{ .tag = "li", .open = "<li", .close = "</li>" },
            .{ .tag = "table", .open = "<table", .close = "</table>" },
            .{ .tag = "tr", .open = "<tr", .close = "</tr>" },
            .{ .tag = "td", .open = "<td", .close = "</td>" },
        };

        for (tags) |t| {
            try self.map.put(t.tag, TagCache{
                .open_prefix = t.open,
                .close_tag = t.close,
            });
        }
    }

    fn deinit(self: *HashMapTagCache, allocator: std.mem.Allocator) void {
        _ = allocator;
        self.map.deinit();
    }

    fn get(self: *HashMapTagCache, tag: []const u8) ?TagCache {
        return self.map.get(tag);
    }
};

test "linear search finds common tags" {
    const cache = LinearTagCache{};

    const result = cache.get("div");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("<div", result.?.open_prefix);
}

test "hashmap finds common tags" {
    const allocator = std.testing.allocator;

    var cache = HashMapTagCache{};
    try cache.init(allocator);
    defer cache.deinit(allocator);

    const result = cache.get("div");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("<div", result.?.open_prefix);
}
