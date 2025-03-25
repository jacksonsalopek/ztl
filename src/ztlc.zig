const std = @import("std");

// Helper type for string literal
pub const Str = []const u8;

// Pre-defined buffer size for initial allocation
const INITIAL_BUFFER_SIZE = 4096;

// Tag cache for common HTML tags
const TagCache = struct {
    open_prefix: []const u8, // e.g. "<div"
    close_tag: []const u8, // e.g. "</div>"
};

// HTML elements are either text or DOM objects
pub const El = union(enum) {
    base: BaseTag,
    text: []const u8, // Changed from []u8 to []const u8 to avoid duplication of literals

    fn isText(self: El) bool {
        return switch (self) {
            .text => true,
            else => false,
        };
    }

    pub fn render(self: El, buf: *std.ArrayList(u8), compact: bool) !void {
        switch (self) {
            .base => |base| try base.render(buf, compact),
            .text => |text| try buf.appendSlice(text),
        }
    }
};

// Helper type for element children
pub const Children = ?[]const El;

// Helper function for writing attributes to reduce repeated code
fn writeAttr(buf: *std.ArrayList(u8), name: []const u8, value: []const u8) !void {
    // Pre-allocate space for the entire attribute to avoid multiple allocations
    const total_length = 1 + name.len + 2 + value.len + 1; // " " + name + "=\"" + value + "\""
    try buf.ensureUnusedCapacity(total_length);

    try buf.appendSlice(" ");
    try buf.appendSlice(name);
    try buf.appendSlice("=\"");
    try buf.appendSlice(value);
    try buf.appendSlice("\"");
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

    pub fn render(self: ARIAProps, buf: *std.ArrayList(u8)) !void {
        // Define a list of property-value pairs to avoid repeated code
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

        // Loop through properties instead of repeated conditionals
        for (props) |prop| {
            if (prop.value) |value| {
                try writeAttr(buf, prop.name, value);
            }
        }
    }
};

// See htmx.org for more info on HTMX
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

    pub fn render(self: HTMXProps, buf: *std.ArrayList(u8)) !void {
        // Define a list of property-value pairs to avoid repeated code
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

        // Loop through properties instead of repeated conditionals
        for (props) |prop| {
            if (prop.value) |value| {
                try writeAttr(buf, prop.name, value);
            }
        }
    }
};

// DOM properties for HTML elements
pub const Props = struct {
    alt: ?Str = null,
    aria: ?ARIAProps = null,
    class: ?Str = null,
    charset: ?Str = null,
    // @TODO: convert to bool
    checked: ?Str = null,
    content: ?Str = null,
    // @TODO: convert to bool
    disabled: ?Str = null,
    // @TODO: convert to u16
    height: ?Str = null,
    href: ?Str = null,
    hx: ?HTMXProps = null,
    id: ?Str = null,
    lang: ?Str = null,
    name: ?Str = null,
    rel: ?Str = null,
    // @TODO: convert to bool
    selected: ?Str = null,
    src: ?Str = null,
    style: ?Str = null,
    title: ?Str = null,
    type: ?Str = null,
    value: ?Str = null,
    // @TODO: convert to u16
    width: ?Str = null,

    pub fn render(self: Props, buf: *std.ArrayList(u8)) !void {
        // Specialized properties
        if (self.aria) |aria| {
            try aria.render(buf);
        }
        if (self.hx) |hx| {
            try hx.render(buf);
        }

        // Regular properties using a data-driven approach
        const props = [_]struct { name: []const u8, value: ?Str }{
            .{ .name = "alt", .value = self.alt },
            .{ .name = "class", .value = self.class },
            .{ .name = "charset", .value = self.charset },
            .{ .name = "checked", .value = self.checked },
            .{ .name = "content", .value = self.content },
            .{ .name = "disabled", .value = self.disabled },
            .{ .name = "height", .value = self.height },
            .{ .name = "href", .value = self.href },
            .{ .name = "id", .value = self.id },
            .{ .name = "lang", .value = self.lang },
            .{ .name = "name", .value = self.name },
            .{ .name = "rel", .value = self.rel },
            .{ .name = "selected", .value = self.selected },
            .{ .name = "src", .value = self.src },
            .{ .name = "style", .value = self.style },
            .{ .name = "title", .value = self.title },
            .{ .name = "type", .value = self.type },
            .{ .name = "value", .value = self.value },
            .{ .name = "width", .value = self.width },
        };

        // Loop through properties instead of repeated conditionals
        for (props) |prop| {
            if (prop.value) |value| {
                try writeAttr(buf, prop.name, value);
            }
        }
    }
};

// Use comptime to generate tag cache with zero runtime allocation
const ComptimeTagCache = struct {
    // Generate the tag cache at compile time
    const common_tags = [_][]const u8{ "html", "head", "body", "div", "span", "p", "h1", "h2", "h3", "a", "ul", "ol", "li", "table", "tr", "td", "th" };

    // Comptime function to create tag cache entries
    fn makeTagCacheEntries() [common_tags.len]struct { tag: []const u8, cache: TagCache } {
        var result: [common_tags.len]struct { tag: []const u8, cache: TagCache } = undefined;

        inline for (common_tags, 0..) |tag, i| {
            // These strings are compile-time constants, no allocation needed
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

    // Create the cache entries at compile time
    const entries = makeTagCacheEntries();
};

// Function to find a tag in the comptime cache
fn getTagFromCache(tag: []const u8) ?TagCache {
    inline for (ComptimeTagCache.entries) |entry| {
        if (std.mem.eql(u8, tag, entry.tag)) {
            return entry.cache;
        }
    }
    return null;
}

pub const BaseTag = struct {
    tag: Str,
    children: Children,
    props: ?Props = null,

    pub fn render(self: BaseTag, buf: *std.ArrayList(u8), compact: bool) anyerror!void {
        // Special case for HTML tag
        if (std.mem.eql(u8, self.tag, "html")) {
            try buf.appendSlice("<!DOCTYPE html>\n<html");
        } else {
            // Try to use the comptime tag cache
            if (getTagFromCache(self.tag)) |cached| {
                try buf.appendSlice(cached.open_prefix);
            } else {
                // Fall back for uncached tags
                try buf.appendSlice("<");
                try buf.appendSlice(self.tag);
            }
        }

        // Add properties
        if (self.props) |props| {
            try props.render(buf);
        }

        try buf.appendSlice(">");
        if (!compact) {
            try buf.appendSlice("\n");
        }

        // Render children
        if (self.children) |children| {
            for (children) |child| {
                try child.render(buf, compact);
            }
        }

        // Close tag
        if (getTagFromCache(self.tag)) |cached| {
            try buf.appendSlice(cached.close_tag);
        } else {
            try buf.appendSlice("</");
            try buf.appendSlice(self.tag);
            try buf.appendSlice(">");
        }

        if (!compact) {
            try buf.appendSlice("\n");
        }
    }

    pub fn el(self: BaseTag) El {
        return El{ .base = self };
    }
};

pub const ZTLBuilder = struct {
    allocator: std.mem.Allocator,
    // Track string allocations (for text content and tag names)
    string_allocations: std.ArrayList([]u8),
    // Track element array allocations
    element_allocations: std.ArrayList([]El),
    // Flag to indicate if we should copy string literals
    copy_literals: bool,

    pub fn init(allocator: std.mem.Allocator) !ZTLBuilder {
        return ZTLBuilder{
            .allocator = allocator,
            .string_allocations = std.ArrayList([]u8).init(allocator),
            .element_allocations = std.ArrayList([]El).init(allocator),
            .copy_literals = false, // Default to not copying literals
        };
    }

    pub fn deinit(self: *ZTLBuilder) void {
        // Free all string allocations (text content and tag names)
        for (self.string_allocations.items) |allocation| {
            self.allocator.free(allocation);
        }
        self.string_allocations.deinit();

        // Free all element array allocations
        for (self.element_allocations.items) |allocation| {
            self.allocator.free(allocation);
        }
        self.element_allocations.deinit();
    }

    pub fn text(self: *ZTLBuilder, content: Str) El {
        if (self.copy_literals) {
            const copy = self.allocator.dupe(u8, content) catch unreachable;
            self.string_allocations.append(copy) catch unreachable;
            return El{ .text = copy };
        } else {
            // Use the string literal directly for static content
            return El{ .text = content };
        }
    }

    fn baseElementConfig(self: *ZTLBuilder, tag: Str, props: ?Props, children: Children) BaseTag {
        var tagToUse = tag;

        // Only duplicate the tag if we're configured to copy literals
        if (self.copy_literals) {
            const tagCopy = self.allocator.dupe(u8, tag) catch unreachable;
            self.string_allocations.append(tagCopy) catch unreachable;
            tagToUse = tagCopy;
        }

        // Allocate and track children array if present
        var childrenCopy: ?[]const El = null;
        if (children) |c| {
            const elCopy = self.allocator.dupe(El, c) catch unreachable;
            self.element_allocations.append(elCopy) catch unreachable;
            childrenCopy = elCopy;
        }

        return BaseTag{ .tag = tagToUse, .children = childrenCopy, .props = props };
    }

    // Pre-allocate the output buffer for more efficient rendering
    pub fn renderToString(self: *ZTLBuilder, root: El, compact: bool) ![]u8 {
        var buf = try std.ArrayList(u8).initCapacity(self.allocator, INITIAL_BUFFER_SIZE);
        try root.render(&buf, compact);
        return buf.toOwnedSlice();
    }

    // Generate the tag methods using a comptime function to reduce code duplication
    pub usingnamespace genTagMethods();
};

// Generate tag methods at compile time to reduce code duplication
fn genTagMethods() type {
    return struct {
        // Define all HTML tag methods here
        pub fn html(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("html", props, children);
        }

        pub fn a(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("a", props, children);
        }

        pub fn b(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("b", props, children);
        }

        pub fn body(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("body", props, children);
        }

        pub fn div(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("div", props, children);
        }

        pub fn h1(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("h1", props, children);
        }

        pub fn h2(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("h2", props, children);
        }

        pub fn h3(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("h3", props, children);
        }

        pub fn h4(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("h4", props, children);
        }

        pub fn h5(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("h5", props, children);
        }

        pub fn h6(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("h6", props, children);
        }

        pub fn head(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("head", props, children);
        }

        pub fn hr(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("hr", props, children);
        }

        pub fn i(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("i", props, children);
        }

        pub fn img(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("img", props, children);
        }

        pub fn li(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("li", props, children);
        }

        pub fn link(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("link", props, children);
        }

        pub fn meta(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("meta", props, children);
        }

        pub fn nav(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("nav", props, children);
        }

        pub fn ol(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("ol", props, children);
        }

        pub fn p(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("p", props, children);
        }

        pub fn script(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("script", props, children);
        }

        pub fn span(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("span", props, children);
        }

        pub fn table(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("table", props, children);
        }

        pub fn td(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("td", props, children);
        }

        pub fn th(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("th", props, children);
        }

        pub fn title(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("title", props, children);
        }

        pub fn tr(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("tr", props, children);
        }

        pub fn ul(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
            return self.baseElementConfig("ul", props, children);
        }
    };
}
