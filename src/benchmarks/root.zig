//! Benchmark infrastructure for ztl HTML templating library
//! 
//! This module provides common utilities for performance benchmarking:
//! - Timer: High-precision timing
//! - AllocTracker: Memory allocation tracking
//! - Result: Standardized result reporting
//! - Comparison utilities for baseline vs optimized measurements

const std = @import("std");

/// High-precision timer for measuring execution time
pub const Timer = struct {
    timer: std.time.Timer,

    pub fn start() !Timer {
        return Timer{
            .timer = try std.time.Timer.start(),
        };
    }

    pub fn read(self: *Timer) u64 {
        return self.timer.read();
    }

    pub fn reset(self: *Timer) void {
        self.timer.reset();
    }
};

/// Memory allocation tracker for profiling
pub const AllocTracker = struct {
    parent_allocator: std.mem.Allocator,
    allocations: usize = 0,
    bytes: usize = 0,
    frees: usize = 0,

    pub fn allocator(self: *AllocTracker) std.mem.Allocator {
        return .{
            .ptr = self,
            .vtable = &.{
                .alloc = alloc,
                .resize = resize,
                .free = free,
                .remap = remap,
            },
        };
    }

    fn alloc(ctx: *anyopaque, len: usize, ptr_align: std.mem.Alignment, ret_addr: usize) ?[*]u8 {
        const self: *AllocTracker = @ptrCast(@alignCast(ctx));
        const result = self.parent_allocator.rawAlloc(len, ptr_align, ret_addr);
        if (result != null) {
            self.allocations += 1;
            self.bytes += len;
        }
        return result;
    }

    fn resize(ctx: *anyopaque, buf: []u8, buf_align: std.mem.Alignment, new_len: usize, ret_addr: usize) bool {
        const self: *AllocTracker = @ptrCast(@alignCast(ctx));
        if (self.parent_allocator.rawResize(buf, buf_align, new_len, ret_addr)) {
            if (new_len > buf.len) {
                self.bytes += new_len - buf.len;
            }
            return true;
        }
        return false;
    }

    fn free(ctx: *anyopaque, buf: []u8, buf_align: std.mem.Alignment, ret_addr: usize) void {
        const self: *AllocTracker = @ptrCast(@alignCast(ctx));
        self.frees += 1;
        self.parent_allocator.rawFree(buf, buf_align, ret_addr);
    }

    fn remap(ctx: *anyopaque, old_buf: []u8, old_align: std.mem.Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
        const self: *AllocTracker = @ptrCast(@alignCast(ctx));
        const result = self.parent_allocator.rawRemap(old_buf, old_align, new_len, ret_addr);
        if (result != null) {
            if (new_len > old_buf.len) {
                self.bytes += new_len - old_buf.len;
            }
        }
        return result;
    }

    pub const AllocStats = struct {
        allocations: usize,
        bytes: usize,
        frees: usize,
    };

    pub fn snapshot(self: *AllocTracker) AllocStats {
        return .{
            .allocations = self.allocations,
            .bytes = self.bytes,
            .frees = self.frees,
        };
    }

    pub fn reset(self: *AllocTracker) void {
        self.allocations = 0;
        self.bytes = 0;
        self.frees = 0;
    }
};

/// Standardized benchmark result
pub const Result = struct {
    name: []const u8,
    time_ns: u64,
    allocations: usize = 0,
    bytes_allocated: usize = 0,
    iterations: usize = 1,

    pub fn print(self: Result, writer: anytype) !void {
        try writer.print("  {s}:\n", .{self.name});
        
        const time_per_iter = if (self.iterations > 0) self.time_ns / self.iterations else self.time_ns;
        try writer.print("    Time: {d}ns", .{time_per_iter});
        if (self.iterations > 1) {
            try writer.print(" (avg of {d} iterations)", .{self.iterations});
        }
        try writer.print("\n", .{});
        
        if (self.allocations > 0) {
            try writer.print("    Allocations: {d}\n", .{self.allocations});
        }
        if (self.bytes_allocated > 0) {
            try writer.print("    Bytes: {d}\n", .{self.bytes_allocated});
        }
    }

    /// Compare two results and show improvement
    pub fn compare(baseline: Result, optimized: Result, writer: anytype) !void {
        try writer.print("\n  Comparison ({s} vs {s}):\n", .{ baseline.name, optimized.name });
        
        const baseline_time = if (baseline.iterations > 0) baseline.time_ns / baseline.iterations else baseline.time_ns;
        const optimized_time = if (optimized.iterations > 0) optimized.time_ns / optimized.iterations else optimized.time_ns;
        
        if (baseline_time > 0) {
            const time_ratio = @as(f64, @floatFromInt(baseline_time)) / @as(f64, @floatFromInt(optimized_time));
            const time_improvement = ((time_ratio - 1.0) * 100.0);
            
            if (time_improvement > 0) {
                try writer.print("    ✓ {d:.1}% faster\n", .{time_improvement});
            } else {
                try writer.print("    ✗ {d:.1}% slower\n", .{-time_improvement});
            }
        }
        
        if (baseline.allocations > 0 and optimized.allocations != baseline.allocations) {
            const alloc_saved = @as(i64, @intCast(baseline.allocations)) - @as(i64, @intCast(optimized.allocations));
            if (alloc_saved > 0) {
                try writer.print("    ✓ {d} fewer allocations\n", .{alloc_saved});
            } else {
                try writer.print("    ✗ {d} more allocations\n", .{-alloc_saved});
            }
        }
        
        if (baseline.bytes_allocated > 0 and optimized.bytes_allocated != baseline.bytes_allocated) {
            const bytes_saved = @as(i64, @intCast(baseline.bytes_allocated)) - @as(i64, @intCast(optimized.bytes_allocated));
            if (bytes_saved > 0) {
                try writer.print("    ✓ {d} fewer bytes\n", .{bytes_saved});
            } else {
                try writer.print("    ✗ {d} more bytes\n", .{-bytes_saved});
            }
        }
    }
};

/// Statistics calculator for multiple samples
pub const Stats = struct {
    avg: u64,
    min: u64,
    max: u64,
    median: u64,

    pub fn calculate(samples: []u64) Stats {
        if (samples.len == 0) return .{ .avg = 0, .min = 0, .max = 0, .median = 0 };
        
        var total: u64 = 0;
        var min_val: u64 = std.math.maxInt(u64);
        var max_val: u64 = 0;
        
        for (samples) |sample| {
            total += sample;
            if (sample < min_val) min_val = sample;
            if (sample > max_val) max_val = sample;
        }
        
        const avg_val = total / samples.len;
        
        // Calculate median (requires sorting a copy)
        const sorted = std.heap.page_allocator.dupe(u64, samples) catch samples;
        defer if (sorted.ptr != samples.ptr) std.heap.page_allocator.free(sorted);
        std.mem.sort(u64, sorted, {}, comptime std.sort.asc(u64));
        const median_val = sorted[sorted.len / 2];
        
        return .{
            .avg = avg_val,
            .min = min_val,
            .max = max_val,
            .median = median_val,
        };
    }

    pub fn print(self: Stats, writer: anytype) !void {
        try writer.print("    Avg: {d}ns, Min: {d}ns, Max: {d}ns, Median: {d}ns\n", .{
            self.avg,
            self.min,
            self.max,
            self.median,
        });
    }
};

// Export benchmark modules
pub const html_escaping = @import("html_escaping.zig");
pub const struct_packing = @import("struct_packing.zig");
pub const tag_cache = @import("tag_cache.zig");
pub const buffer_growth = @import("buffer_growth.zig");
pub const rendering = @import("rendering.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stdout = std.fs.File.stdout().deprecatedWriter();

    // Parse command line arguments
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.skip(); // skip program name

    const benchmark_name = args.next();

    if (benchmark_name) |name| {
        try runByName(allocator, name, stdout);
    } else {
        try runAll(allocator, stdout);
    }
}

pub fn runByName(allocator: std.mem.Allocator, name: []const u8, writer: anytype) !void {
    if (std.mem.eql(u8, name, "html-escaping")) {
        try html_escaping.run(allocator, writer);
    } else if (std.mem.eql(u8, name, "struct-packing")) {
        try struct_packing.run(allocator, writer);
    } else if (std.mem.eql(u8, name, "tag-cache")) {
        try tag_cache.run(allocator, writer);
    } else if (std.mem.eql(u8, name, "buffer-growth")) {
        try buffer_growth.run(allocator, writer);
    } else if (std.mem.eql(u8, name, "rendering")) {
        try rendering.run(allocator, writer);
    } else {
        try writer.print("Unknown benchmark: {s}\n", .{name});
        try writer.print("Available benchmarks:\n", .{});
        try writer.print("  html-escaping   - HTML entity escaping (scalar baseline)\n", .{});
        try writer.print("  struct-packing  - Packed vs regular struct performance\n", .{});
        try writer.print("  tag-cache       - Tag cache lookup strategies\n", .{});
        try writer.print("  buffer-growth   - Buffer growth strategies\n", .{});
        try writer.print("  rendering       - End-to-end rendering performance\n", .{});
        return error.UnknownBenchmark;
    }
}

pub fn runAll(allocator: std.mem.Allocator, writer: anytype) !void {
    try writer.print("\n", .{});
    try writer.print("=" ** 70, .{});
    try writer.print("\n", .{});
    try writer.print("ZTL HTML Templating Library - Performance Benchmarks\n", .{});
    try writer.print("=" ** 70, .{});
    try writer.print("\n\n", .{});

    try writer.print("Running End-to-End Rendering Benchmark...\n", .{});
    try rendering.run(allocator, writer);

    try writer.print("\n", .{});
    try writer.print("Running HTML Escaping Benchmark...\n", .{});
    try html_escaping.run(allocator, writer);

    try writer.print("\n", .{});
    try writer.print("Running Struct Packing Benchmark...\n", .{});
    try struct_packing.run(allocator, writer);

    try writer.print("\n", .{});
    try writer.print("Running Tag Cache Benchmark...\n", .{});
    try tag_cache.run(allocator, writer);

    try writer.print("\n", .{});
    try writer.print("Running Buffer Growth Benchmark...\n", .{});
    try buffer_growth.run(allocator, writer);

    try writer.print("\n", .{});
    try writer.print("=" ** 70, .{});
    try writer.print("\n", .{});
    try writer.print("✓ All benchmarks completed!\n", .{});
    try writer.print("=" ** 70, .{});
    try writer.print("\n", .{});
}
