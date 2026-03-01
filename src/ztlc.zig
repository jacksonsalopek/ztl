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
pub const Element = union(enum) {
    base: BaseTag,
    text: []const u8, // Changed from []u8 to []const u8 to avoid duplication of literals

    fn isText(self: Element) bool {
        return switch (self) {
            .text => true,
            else => false,
        };
    }

    pub fn render(self: Element, buf: *std.ArrayList(u8), allocator: std.mem.Allocator, compact: bool) !void {
        switch (self) {
            .base => |base| try base.render(buf, allocator, compact),
            .text => |text| try buf.appendSlice(allocator, text),
        }
    }
};

// Helper type for element children
pub const Children = ?[]const Element;

// Helper function for writing attributes to reduce repeated code
fn writeAttr(buf: *std.ArrayList(u8), allocator: std.mem.Allocator, name: []const u8, value: []const u8) !void {
    // Pre-allocate space for the entire attribute to avoid multiple allocations
    const total_length = 1 + name.len + 2 + value.len + 1; // " " + name + "=\"" + value + "\""
    try buf.ensureUnusedCapacity(allocator, total_length);

    try buf.appendSlice(allocator, " ");
    try buf.appendSlice(allocator, name);
    try buf.appendSlice(allocator, "=\"");
    try buf.appendSlice(allocator, value);
    try buf.appendSlice(allocator, "\"");
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

    pub fn render(self: ARIAProps, buf: *std.ArrayList(u8), allocator: std.mem.Allocator) !void {
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
                try writeAttr(buf, allocator, prop.name, value);
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

    pub fn render(self: HTMXProps, buf: *std.ArrayList(u8), allocator: std.mem.Allocator) !void {
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
                try writeAttr(buf, allocator, prop.name, value);
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

    pub fn render(self: Props, buf: *std.ArrayList(u8), allocator: std.mem.Allocator) !void {
        // Specialized properties
        if (self.aria) |aria| {
            try aria.render(buf, allocator);
        }
        if (self.hx) |hx| {
            try hx.render(buf, allocator);
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
                try writeAttr(buf, allocator, prop.name, value);
            }
        }
    }
};

const TagCacheEntry = struct {
    tag: []const u8,
    cache: TagCache,
};

// Use comptime to generate tag cache with zero runtime allocation
const ComptimeTagCache = struct {
    // Generate the tag cache at compile time
    const common_tags = [_][]const u8{ "html", "head", "body", "div", "span", "p", "h1", "h2", "h3", "a", "ul", "ol", "li", "table", "tr", "td", "th" };

    // Comptime function to create tag cache entries
    fn makeTagCacheEntries() [common_tags.len]TagCacheEntry {
        var result: [common_tags.len]TagCacheEntry = undefined;

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

    pub fn render(self: BaseTag, buf: *std.ArrayList(u8), allocator: std.mem.Allocator, compact: bool) anyerror!void {
        // Special case for HTML tag
        if (std.mem.eql(u8, self.tag, "html")) {
            try buf.appendSlice(allocator, "<!DOCTYPE html>\n<html");
        } else {
            // Try to use the comptime tag cache
            if (getTagFromCache(self.tag)) |cached| {
                try buf.appendSlice(allocator, cached.open_prefix);
            } else {
                // Fall back for uncached tags
                try buf.appendSlice(allocator, "<");
                try buf.appendSlice(allocator, self.tag);
            }
        }

        // Add properties
        if (self.props) |props| {
            try props.render(buf, allocator);
        }

        try buf.appendSlice(allocator, ">");
        if (!compact) {
            try buf.appendSlice(allocator, "\n");
        }

        // Render children
        if (self.children) |children| {
            for (children) |child| {
                try child.render(buf, allocator, compact);
            }
        }

        // Close tag
        if (getTagFromCache(self.tag)) |cached| {
            try buf.appendSlice(allocator, cached.close_tag);
        } else {
            try buf.appendSlice(allocator, "</");
            try buf.appendSlice(allocator, self.tag);
            try buf.appendSlice(allocator, ">");
        }

        if (!compact) {
            try buf.appendSlice(allocator, "\n");
        }
    }

    pub fn el(self: BaseTag) Element {
        return Element{ .base = self };
    }
};

pub const Builder = struct {
    allocator: std.mem.Allocator,
    // Track string allocations (for text content and tag names)
    string_allocations: std.ArrayList([]u8),
    // Track element array allocations
    element_allocations: std.ArrayList([]Element),
    // Flag to indicate if we should copy string literals
    copy_literals: bool,

    pub fn init(allocator: std.mem.Allocator) !Builder {
        return Builder{
            .allocator = allocator,
            .string_allocations = std.ArrayList([]u8){},
            .element_allocations = std.ArrayList([]Element){},
            .copy_literals = false, // Default to not copying literals
        };
    }

    pub fn deinit(self: *Builder) void {
        // Free all string allocations (text content and tag names)
        for (self.string_allocations.items) |allocation| {
            self.allocator.free(allocation);
        }
        self.string_allocations.deinit(self.allocator);

        // Free all element array allocations
        for (self.element_allocations.items) |allocation| {
            self.allocator.free(allocation);
        }
        self.element_allocations.deinit(self.allocator);
    }

    pub fn text(self: *Builder, content: Str) Element {
        if (self.copy_literals) {
            const copy = self.allocator.dupe(u8, content) catch unreachable;
            self.string_allocations.append(self.allocator, copy) catch unreachable;
            return Element{ .text = copy };
        } else {
            // Use the string literal directly for static content
            return Element{ .text = content };
        }
    }

    fn baseElementConfig(self: *Builder, tag: Str, props: ?Props, children: Children) BaseTag {
        var tagToUse = tag;

        // Only duplicate the tag if we're configured to copy literals
        if (self.copy_literals) {
            const tagCopy = self.allocator.dupe(u8, tag) catch unreachable;
            self.string_allocations.append(self.allocator, tagCopy) catch unreachable;
            tagToUse = tagCopy;
        }

        // Allocate and track children array if present
        var childrenCopy: ?[]const Element = null;
        if (children) |c| {
            const elCopy = self.allocator.dupe(Element, c) catch unreachable;
            self.element_allocations.append(self.allocator, elCopy) catch unreachable;
            childrenCopy = elCopy;
        }

        return BaseTag{ .tag = tagToUse, .children = childrenCopy, .props = props };
    }

    // Pre-allocate the output buffer for more efficient rendering
    pub fn renderToString(self: *Builder, root: Element, compact: bool) ![]u8 {
        var buf = try std.ArrayList(u8).initCapacity(self.allocator, INITIAL_BUFFER_SIZE);
        try root.render(&buf, self.allocator, compact);
        return buf.toOwnedSlice(self.allocator);
    }

    pub fn html(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("html", props, children).el();
    }

    pub fn a(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("a", props, children).el();
    }

    pub fn b(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("b", props, children).el();
    }

    pub fn body(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("body", props, children).el();
    }

    pub fn div(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("div", props, children).el();
    }

    pub fn h1(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("h1", props, children).el();
    }

    pub fn h2(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("h2", props, children).el();
    }

    pub fn h3(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("h3", props, children).el();
    }

    pub fn h4(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("h4", props, children).el();
    }

    pub fn h5(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("h5", props, children).el();
    }

    pub fn h6(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("h6", props, children).el();
    }

    pub fn head(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("head", props, children).el();
    }

    pub fn hr(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("hr", props, children).el();
    }

    pub fn i(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("i", props, children).el();
    }

    pub fn img(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("img", props, children).el();
    }

    pub fn li(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("li", props, children).el();
    }

    pub fn link(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("link", props, children).el();
    }

    pub fn meta(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("meta", props, children).el();
    }

    pub fn nav(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("nav", props, children).el();
    }

    pub fn ol(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("ol", props, children).el();
    }

    pub fn p(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("p", props, children).el();
    }

    pub fn script(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("script", props, children).el();
    }

    pub fn span(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("span", props, children).el();
    }

    pub fn table(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("table", props, children).el();
    }

    pub fn td(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("td", props, children).el();
    }

    pub fn th(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("th", props, children).el();
    }

    pub fn title(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("title", props, children).el();
    }

    pub fn tr(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("tr", props, children).el();
    }

    pub fn ul(self: *Builder, props: ?Props, children: Children) Element {
        return self.baseElementConfig("ul", props, children).el();
    }
};
