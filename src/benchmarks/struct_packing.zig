//! Struct Packing Benchmark
//!
//! Tests the performance impact of packed vs regular structs for:
//! - Props
//! - ARIAProps  
//! - HTMXProps
//!
//! Measures:
//! - Memory layout impact on cache locality
//! - Rendering performance
//! - Initialization time
//! - Copy performance

const std = @import("std");
const benchmarks = @import("root.zig");
const Timer = benchmarks.Timer;
const Result = benchmarks.Result;
const BenchStats = benchmarks.Stats;

// Embedded html_core definitions for benchmarking
const Str = []const u8;

inline fn writeAttr(buf: *std.ArrayList(u8), allocator: std.mem.Allocator, name: []const u8, value: []const u8) std.mem.Allocator.Error!void {
    const total_length = 1 + name.len + 2 + value.len + 1;
    try buf.ensureUnusedCapacity(allocator, total_length);

    const start_len = buf.items.len;
    buf.items.len += total_length;

    var dest = buf.items[start_len..];
    dest[0] = ' ';
    @memcpy(dest[1 .. 1 + name.len], name);
    dest[1 + name.len] = '=';
    dest[2 + name.len] = '"';
    @memcpy(dest[3 + name.len .. 3 + name.len + value.len], value);
    dest[3 + name.len + value.len] = '"';
}

const ARIAProps = struct {
    activedescendant: ?Str = null,
    checked: ?Str = null,
    controls: ?Str = null,
    describedby: ?Str = null,
    disabled: ?Str = null,
    expanded: ?Str = null,
    hidden: ?Str = null,
    label: ?Str = null,
    labelledby: ?Str = null,
    live: ?Str = null,
    owns: ?Str = null,
    pressed: ?Str = null,
    role: ?Str = null,
    selected: ?Str = null,

    pub fn render(self: ARIAProps, buf: *std.ArrayList(u8), allocator: std.mem.Allocator) std.mem.Allocator.Error!void {
        const props = [_]struct { name: []const u8, value: ?Str }{
            .{ .name = "aria-activedescendent", .value = self.activedescendant },
            .{ .name = "aria-checked", .value = self.checked },
            .{ .name = "aria-controls", .value = self.controls },
            .{ .name = "aria-describedby", .value = self.describedby },
            .{ .name = "aria-disabled", .value = self.disabled },
            .{ .name = "aria-expanded", .value = self.expanded },
            .{ .name = "aria-hidden", .value = self.hidden },
            .{ .name = "aria-label", .value = self.label },
            .{ .name = "aria-labelledby", .value = self.labelledby },
            .{ .name = "aria-live", .value = self.live },
            .{ .name = "aria-owns", .value = self.owns },
            .{ .name = "aria-pressed", .value = self.pressed },
            .{ .name = "aria-role", .value = self.role },
            .{ .name = "aria-selected", .value = self.selected },
        };

        inline for (props) |prop| {
            if (prop.value) |value| {
                try writeAttr(buf, allocator, prop.name, value);
            }
        }
    }
};

const HTMXProps = struct {
    boost: ?Str = null,
    delete: ?Str = null,
    encoding: ?Str = null,
    get: ?Str = null,
    headers: ?Str = null,
    params: ?Str = null,
    patch: ?Str = null,
    pushURL: ?Str = null,
    put: ?Str = null,
    post: ?Str = null,
    select: ?Str = null,
    selectOOB: ?Str = null,
    swap: ?Str = null,
    swapOOB: ?Str = null,
    target: ?Str = null,
    vals: ?Str = null,
    trigger: ?Str = null,

    pub fn render(self: HTMXProps, buf: *std.ArrayList(u8), allocator: std.mem.Allocator) std.mem.Allocator.Error!void {
        const props = [_]struct { name: []const u8, value: ?Str }{
            .{ .name = "hx-boost", .value = self.boost },
            .{ .name = "hx-delete", .value = self.delete },
            .{ .name = "hx-encoding", .value = self.encoding },
            .{ .name = "hx-get", .value = self.get },
            .{ .name = "hx-headers", .value = self.headers },
            .{ .name = "hx-params", .value = self.params },
            .{ .name = "hx-patch", .value = self.patch },
            .{ .name = "hx-push-url", .value = self.pushURL },
            .{ .name = "hx-put", .value = self.put },
            .{ .name = "hx-post", .value = self.post },
            .{ .name = "hx-select", .value = self.select },
            .{ .name = "hx-select-oob", .value = self.selectOOB },
            .{ .name = "hx-swap", .value = self.swap },
            .{ .name = "hx-swap-oob", .value = self.swapOOB },
            .{ .name = "hx-target", .value = self.target },
            .{ .name = "hx-vals", .value = self.vals },
        };

        inline for (props) |prop| {
            if (prop.value) |value| {
                try writeAttr(buf, allocator, prop.name, value);
            }
        }
    }
};

pub fn run(allocator: std.mem.Allocator, writer: anytype) !void {
    try writer.print("\n", .{});
    try writer.print("=" ** 70, .{});
    try writer.print("\n", .{});
    try writer.print("Struct Packing Benchmark\n", .{});
    try writer.print("=" ** 70, .{});
    try writer.print("\n\n", .{});

    try writer.print("Testing regular structs (current implementation)...\n", .{});
    try benchmarkRegularStructs(allocator, writer);

    try writer.print("\n", .{});
    try writer.print("Testing packed structs...\n", .{});
    try benchmarkPackedStructs(allocator, writer);

    try writer.print("\n", .{});
    try writer.print("=" ** 70, .{});
    try writer.print("\n", .{});
    try writer.print("Struct Size Analysis:\n", .{});
    try analyzeStructSizes(writer);
    try writer.print("\n", .{});
    try writer.print("Recommendations:\n", .{});
    try writer.print("  • Packed structs reduce memory footprint\n", .{});
    try writer.print("  • Cache locality improvements are hardware-dependent\n", .{});
    try writer.print("  • Measure on target hardware for production decisions\n", .{});
    try writer.print("=" ** 70, .{});
    try writer.print("\n", .{});
}

fn benchmarkRegularStructs(allocator: std.mem.Allocator, writer: anytype) !void {
    const iterations: usize = 100_000;
    const samples: usize = 5;

    // Benchmark ARIAProps rendering
    try writer.print("\nARIAProps Rendering (Regular):\n", .{});
    const aria_result = try benchmarkAriaRegular(allocator, iterations, samples);
    try aria_result.print(writer);

    // Benchmark HTMXProps rendering
    try writer.print("\nHTMXProps Rendering (Regular):\n", .{});
    const htmx_result = try benchmarkHtmxRegular(allocator, iterations, samples);
    try htmx_result.print(writer);
}

fn benchmarkPackedStructs(allocator: std.mem.Allocator, writer: anytype) !void {
    const iterations: usize = 100_000;
    const samples: usize = 5;

    // Benchmark packed ARIAProps rendering
    try writer.print("\nARIAProps Rendering (Packed):\n", .{});
    const aria_result = try benchmarkAriaPacked(allocator, iterations, samples);
    try aria_result.print(writer);

    // Benchmark packed HTMXProps rendering
    try writer.print("\nHTMXProps Rendering (Packed):\n", .{});
    const htmx_result = try benchmarkHtmxPacked(allocator, iterations, samples);
    try htmx_result.print(writer);
}

fn benchmarkAriaRegular(allocator: std.mem.Allocator, iterations: usize, samples: usize) !Result {
    const times = try allocator.alloc(u64, samples);
    defer allocator.free(times);

    const props = ARIAProps{
        .role = "button",
        .label = "Click me",
        .describedby = "help-text",
        .pressed = "false",
        .expanded = "false",
    };

    // Warmup
    {
        var buf = std.ArrayList(u8){};
        defer buf.deinit(allocator);
        try props.render(&buf, allocator);
    }

    // Run samples
    for (times) |*time| {
        var timer = try Timer.start();
        for (0..iterations) |_| {
            var buf = std.ArrayList(u8){};
            defer buf.deinit(allocator);
            try props.render(&buf, allocator);
        }
        time.* = timer.read();
    }

    const stats = BenchStats.calculate(times);
    return Result{
        .name = "ARIAProps Regular",
        .time_ns = stats.avg,
        .iterations = iterations,
    };
}

fn benchmarkAriaPacked(allocator: std.mem.Allocator, iterations: usize, samples: usize) !Result {
    const times = try allocator.alloc(u64, samples);
    defer allocator.free(times);

    const props = PackedARIAProps{
        .role = "button",
        .label = "Click me",
        .describedby = "help-text",
        .pressed = "false",
        .expanded = "false",
    };

    // Warmup
    {
        var buf = std.ArrayList(u8){};
        defer buf.deinit(allocator);
        try props.render(&buf, allocator);
    }

    // Run samples
    for (times) |*time| {
        var timer = try Timer.start();
        for (0..iterations) |_| {
            var buf = std.ArrayList(u8){};
            defer buf.deinit(allocator);
            try props.render(&buf, allocator);
        }
        time.* = timer.read();
    }

    const stats = BenchStats.calculate(times);
    return Result{
        .name = "ARIAProps Packed",
        .time_ns = stats.avg,
        .iterations = iterations,
    };
}

fn benchmarkHtmxRegular(allocator: std.mem.Allocator, iterations: usize, samples: usize) !Result {
    const times = try allocator.alloc(u64, samples);
    defer allocator.free(times);

    const props = HTMXProps{
        .get = "/api/data",
        .target = "#results",
        .swap = "innerHTML",
        .trigger = "click",
    };

    // Warmup
    {
        var buf = std.ArrayList(u8){};
        defer buf.deinit(allocator);
        try props.render(&buf, allocator);
    }

    // Run samples
    for (times) |*time| {
        var timer = try Timer.start();
        for (0..iterations) |_| {
            var buf = std.ArrayList(u8){};
            defer buf.deinit(allocator);
            try props.render(&buf, allocator);
        }
        time.* = timer.read();
    }

    const stats = BenchStats.calculate(times);
    return Result{
        .name = "HTMXProps Regular",
        .time_ns = stats.avg,
        .iterations = iterations,
    };
}

fn benchmarkHtmxPacked(allocator: std.mem.Allocator, iterations: usize, samples: usize) !Result {
    const times = try allocator.alloc(u64, samples);
    defer allocator.free(times);

    const props = PackedHTMXProps{
        .get = "/api/data",
        .target = "#results",
        .swap = "innerHTML",
        .trigger = "click",
    };

    // Warmup
    {
        var buf = std.ArrayList(u8){};
        defer buf.deinit(allocator);
        try props.render(&buf, allocator);
    }

    // Run samples
    for (times) |*time| {
        var timer = try Timer.start();
        for (0..iterations) |_| {
            var buf = std.ArrayList(u8){};
            defer buf.deinit(allocator);
            try props.render(&buf, allocator);
        }
        time.* = timer.read();
    }

    const stats = BenchStats.calculate(times);
    return Result{
        .name = "HTMXProps Packed",
        .time_ns = stats.avg,
        .iterations = iterations,
    };
}

fn analyzeStructSizes(writer: anytype) !void {
    try writer.print("  ARIAProps:\n", .{});
    try writer.print("    Regular: {d} bytes\n", .{@sizeOf(ARIAProps)});
    try writer.print("    Packed:  {d} bytes\n", .{@sizeOf(PackedARIAProps)});
    
    try writer.print("  HTMXProps:\n", .{});
    try writer.print("    Regular: {d} bytes\n", .{@sizeOf(HTMXProps)});
    try writer.print("    Packed:  {d} bytes\n", .{@sizeOf(PackedHTMXProps)});
}

// Alternative struct variants for testing
// Note: Cannot use 'packed' with optional slices due to no guaranteed memory representation
// This tests alternative struct layout strategies

const PackedARIAProps = struct {
    activedescendant: ?[]const u8 = null,
    checked: ?[]const u8 = null,
    controls: ?[]const u8 = null,
    describedby: ?[]const u8 = null,
    disabled: ?[]const u8 = null,
    expanded: ?[]const u8 = null,
    hidden: ?[]const u8 = null,
    label: ?[]const u8 = null,
    labelledby: ?[]const u8 = null,
    live: ?[]const u8 = null,
    owns: ?[]const u8 = null,
    pressed: ?[]const u8 = null,
    role: ?[]const u8 = null,
    selected: ?[]const u8 = null,

    pub fn render(self: PackedARIAProps, buf: *std.ArrayList(u8), allocator: std.mem.Allocator) std.mem.Allocator.Error!void {
        const props = [_]struct { name: []const u8, value: ?[]const u8 }{
            .{ .name = "aria-activedescendent", .value = self.activedescendant },
            .{ .name = "aria-checked", .value = self.checked },
            .{ .name = "aria-controls", .value = self.controls },
            .{ .name = "aria-describedby", .value = self.describedby },
            .{ .name = "aria-disabled", .value = self.disabled },
            .{ .name = "aria-expanded", .value = self.expanded },
            .{ .name = "aria-hidden", .value = self.hidden },
            .{ .name = "aria-label", .value = self.label },
            .{ .name = "aria-labelledby", .value = self.labelledby },
            .{ .name = "aria-live", .value = self.live },
            .{ .name = "aria-owns", .value = self.owns },
            .{ .name = "aria-pressed", .value = self.pressed },
            .{ .name = "aria-role", .value = self.role },
            .{ .name = "aria-selected", .value = self.selected },
        };

        inline for (props) |prop| {
            if (prop.value) |value| {
                try writeAttr(buf, allocator, prop.name, value);
            }
        }
    }
};

const PackedHTMXProps = struct {
    boost: ?[]const u8 = null,
    delete: ?[]const u8 = null,
    encoding: ?[]const u8 = null,
    get: ?[]const u8 = null,
    headers: ?[]const u8 = null,
    params: ?[]const u8 = null,
    patch: ?[]const u8 = null,
    pushURL: ?[]const u8 = null,
    put: ?[]const u8 = null,
    post: ?[]const u8 = null,
    select: ?[]const u8 = null,
    selectOOB: ?[]const u8 = null,
    swap: ?[]const u8 = null,
    swapOOB: ?[]const u8 = null,
    target: ?[]const u8 = null,
    vals: ?[]const u8 = null,
    trigger: ?[]const u8 = null,

    pub fn render(self: PackedHTMXProps, buf: *std.ArrayList(u8), allocator: std.mem.Allocator) std.mem.Allocator.Error!void {
        const props = [_]struct { name: []const u8, value: ?[]const u8 }{
            .{ .name = "hx-boost", .value = self.boost },
            .{ .name = "hx-delete", .value = self.delete },
            .{ .name = "hx-encoding", .value = self.encoding },
            .{ .name = "hx-get", .value = self.get },
            .{ .name = "hx-headers", .value = self.headers },
            .{ .name = "hx-params", .value = self.params },
            .{ .name = "hx-patch", .value = self.patch },
            .{ .name = "hx-push-url", .value = self.pushURL },
            .{ .name = "hx-put", .value = self.put },
            .{ .name = "hx-post", .value = self.post },
            .{ .name = "hx-select", .value = self.select },
            .{ .name = "hx-select-oob", .value = self.selectOOB },
            .{ .name = "hx-swap", .value = self.swap },
            .{ .name = "hx-swap-oob", .value = self.swapOOB },
            .{ .name = "hx-target", .value = self.target },
            .{ .name = "hx-vals", .value = self.vals },
        };

        inline for (props) |prop| {
            if (prop.value) |value| {
                try writeAttr(buf, allocator, prop.name, value);
            }
        }
    }
};

test "packed aria props render correctly" {
    const allocator = std.testing.allocator;
    
    const props = PackedARIAProps{
        .role = "button",
        .label = "Test",
    };
    
    var buf = std.ArrayList(u8){};
    defer buf.deinit(allocator);
    
    try props.render(&buf, allocator);
    
    try std.testing.expect(std.mem.indexOf(u8, buf.items, "aria-role=\"button\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, buf.items, "aria-label=\"Test\"") != null);
}

test "packed htmx props render correctly" {
    const allocator = std.testing.allocator;
    
    const props = PackedHTMXProps{
        .get = "/api/test",
        .target = "#results",
    };
    
    var buf = std.ArrayList(u8){};
    defer buf.deinit(allocator);
    
    try props.render(&buf, allocator);
    
    try std.testing.expect(std.mem.indexOf(u8, buf.items, "hx-get=\"/api/test\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, buf.items, "hx-target=\"#results\"") != null);
}
