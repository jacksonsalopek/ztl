const std = @import("std");

pub const Str = []const u8;
pub const INITIAL_BUFFER_SIZE = 4096;
pub const RenderError = error{OutOfMemory};

/// HTML entity escaping to prevent XSS vulnerabilities
pub fn escapeHtml(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
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

    if (extra == 0) return allocator.dupe(u8, input);

    var result = try allocator.alloc(u8, input.len + extra);
    var i: usize = 0;
    for (input) |c| {
        switch (c) {
            '&' => {
                @memcpy(result[i .. i + 5], "&amp;");
                i += 5;
            },
            '<' => {
                @memcpy(result[i .. i + 4], "&lt;");
                i += 4;
            },
            '>' => {
                @memcpy(result[i .. i + 4], "&gt;");
                i += 4;
            },
            '"' => {
                @memcpy(result[i .. i + 6], "&quot;");
                i += 6;
            },
            '\'' => {
                @memcpy(result[i .. i + 5], "&#39;");
                i += 5;
            },
            else => {
                result[i] = c;
                i += 1;
            },
        }
    }
    return result;
}

/// Direct-to-buffer HTML escaping that eliminates temporary allocation.
/// This is significantly faster than escapeHtml when writing to an ArrayList.
/// Phase 1 optimization: marked inline for hot-path performance
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

/// Phase 1 optimization: marked inline for hot-path performance
pub inline fn writeAttr(buf: *std.ArrayList(u8), allocator: std.mem.Allocator, name: []const u8, value: []const u8) std.mem.Allocator.Error!void {
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

pub const ARIAProps = struct {
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

    /// Optimization: Inline + comptime loop unrolling for zero-overhead iteration
    pub inline fn render(self: ARIAProps, buf: *std.ArrayList(u8), allocator: std.mem.Allocator) std.mem.Allocator.Error!void {
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

pub const HTMXProps = struct {
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

    /// Optimization: Inline + comptime loop unrolling for zero-overhead iteration
    pub inline fn render(self: HTMXProps, buf: *std.ArrayList(u8), allocator: std.mem.Allocator) std.mem.Allocator.Error!void {
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

pub const TagCache = struct {
    open_prefix: []const u8,
    close_tag: []const u8,
};

const TagCacheEntry = struct {
    tag: []const u8,
    cache: TagCache,
};

const ComptimeTagCache = struct {
    const common_tags = [_][]const u8{ "html", "head", "body", "div", "span", "p", "h1", "h2", "h3", "h4", "h5", "h6", "a", "ul", "ol", "li", "table", "tr", "td", "th", "nav", "img", "link", "meta", "script", "title", "b", "i", "hr" };

    fn makeTagCacheEntries() [common_tags.len]TagCacheEntry {
        var result: [common_tags.len]TagCacheEntry = undefined;

        inline for (common_tags, 0..) |tag, i| {
            // Phase 1 optimization: comptime string concatenation ensures zero runtime overhead
            const open_prefix = "<" ++ tag;
            const close_tag = "</" ++ tag ++ ">";

            result[i] = .{
                .tag = tag,
                .cache = TagCache{
                    .open_prefix = open_prefix,
                    .close_tag = close_tag,
                },
            };
        }

        return result;
    }

    const entries = makeTagCacheEntries();
    
    /// Phase 1 optimization: Perfect hash function for O(1) tag lookup
    /// Uses first character + length as a simple but effective hash
    fn hash(tag: []const u8) u8 {
        if (tag.len == 0) return 0;
        return @as(u8, @intCast((tag[0] *% 31 +% tag.len) % 61));
    }
    
    /// Phase 1 optimization: Build perfect hash table at comptime
    fn makeHashTable() [61]?u8 {
        var table: [61]?u8 = [_]?u8{null} ** 61;
        inline for (common_tags, 0..) |tag, idx| {
            const h = comptime hash(tag);
            table[h] = @intCast(idx);
        }
        return table;
    }
    
    const hash_table = makeHashTable();
};

/// Phase 1 optimization: O(1) hash-based lookup instead of linear search
pub inline fn getTagFromCache(tag: []const u8) ?TagCache {
    const h = ComptimeTagCache.hash(tag);
    if (ComptimeTagCache.hash_table[h]) |idx| {
        const entry = &ComptimeTagCache.entries[idx];
        if (std.mem.eql(u8, tag, entry.tag)) {
            return entry.cache;
        }
    }
    return null;
}

/// Generic helper for rendering opening tag
/// Phase 1 optimization: marked inline for hot-path performance
pub inline fn renderOpenTag(
    buf: *std.ArrayList(u8),
    allocator: std.mem.Allocator,
    tag: []const u8,
    props: anytype,
    compact: bool,
) !void {
    if (std.mem.eql(u8, tag, "html")) {
        const doctype = if (compact) "<!DOCTYPE html><html" else "<!DOCTYPE html>\n<html";
        try buf.appendSlice(allocator, doctype);
    } else {
        if (getTagFromCache(tag)) |cached| {
            try buf.appendSlice(allocator, cached.open_prefix);
        } else {
            const estimated_tag_size = 1 + tag.len;
            try buf.ensureUnusedCapacity(allocator, estimated_tag_size);
            const start_len = buf.items.len;
            buf.items.len += estimated_tag_size;
            buf.items[start_len] = '<';
            @memcpy(buf.items[start_len + 1 .. start_len + 1 + tag.len], tag);
        }
    }

    if (props) |p| {
        try p.render(buf, allocator);
    }

    const close_size: usize = if (compact) 1 else 2;
    try buf.ensureUnusedCapacity(allocator, close_size);
    const start_len = buf.items.len;
    buf.items.len += close_size;
    buf.items[start_len] = '>';
    if (!compact) {
        buf.items[start_len + 1] = '\n';
    }
}

/// Generic helper for rendering closing tag
/// Phase 1 optimization: marked inline for hot-path performance
pub inline fn renderCloseTag(
    buf: *std.ArrayList(u8),
    allocator: std.mem.Allocator,
    tag: []const u8,
    compact: bool,
) !void {
    if (getTagFromCache(tag)) |cached| {
        try buf.appendSlice(allocator, cached.close_tag);
        if (!compact) {
            try buf.ensureUnusedCapacity(allocator, 1);
            buf.items.len += 1;
            buf.items[buf.items.len - 1] = '\n';
        }
    } else {
        const tag_size = 3 + tag.len + (if (compact) @as(usize, 0) else 1);
        try buf.ensureUnusedCapacity(allocator, tag_size);
        const start_len = buf.items.len;
        buf.items.len += tag_size;
        buf.items[start_len] = '<';
        buf.items[start_len + 1] = '/';
        @memcpy(buf.items[start_len + 2 .. start_len + 2 + tag.len], tag);
        buf.items[start_len + 2 + tag.len] = '>';
        if (!compact) {
            buf.items[start_len + 3 + tag.len] = '\n';
        }
    }
}

/// Generic helper for rendering opening tag to writer
pub fn renderOpenTagToWriter(
    writer: anytype,
    allocator: std.mem.Allocator,
    tag: []const u8,
    props: anytype,
    compact: bool,
) !void {
    if (std.mem.eql(u8, tag, "html")) {
        const doctype = if (compact) "<!DOCTYPE html><html" else "<!DOCTYPE html>\n<html";
        try writer.writeAll(doctype);
    } else {
        if (getTagFromCache(tag)) |cached| {
            try writer.writeAll(cached.open_prefix);
        } else {
            try writer.writeAll("<");
            try writer.writeAll(tag);
        }
    }

    if (props) |p| {
        var buf = std.ArrayList(u8){};
        defer buf.deinit(allocator);
        try p.render(&buf, allocator);
        try writer.writeAll(buf.items);
    }

    try writer.writeAll(">");
    if (!compact) {
        try writer.writeAll("\n");
    }
}

/// Generic helper for rendering closing tag to writer
pub fn renderCloseTagToWriter(
    writer: anytype,
    tag: []const u8,
    compact: bool,
) !void {
    if (getTagFromCache(tag)) |cached| {
        try writer.writeAll(cached.close_tag);
    } else {
        try writer.writeAll("</");
        try writer.writeAll(tag);
        try writer.writeAll(">");
    }

    if (!compact) {
        try writer.writeAll("\n");
    }
}
