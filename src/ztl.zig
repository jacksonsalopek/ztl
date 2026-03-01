const std = @import("std");

// Helper type for string literal
pub const Str = []const u8;

// Pre-defined buffer size for initial allocation
const INITIAL_BUFFER_SIZE = 4096;

// HTML elements are either text or DOM objects
pub const Element = union(enum) {
    base: BaseTag,
    text: []u8,

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

    // Helper methods to reduce optional chaining
    pub fn getTag(self: Element) ?[]const u8 {
        return switch (self) {
            .base => |base| base.tag,
            .text => null,
        };
    }

    pub fn getProps(self: Element) ?Props {
        return switch (self) {
            .base => |base| base.props,
            .text => null,
        };
    }

    pub fn getChildren(self: Element) ?[]const Element {
        return switch (self) {
            .base => |base| base.children,
            .text => null,
        };
    }

    pub fn getChild(self: Element, index: usize) ?Element {
        return switch (self) {
            .base => |base| {
                if (base.children) |children| {
                    if (index < children.len) {
                        return children[index];
                    }
                }
                return null;
            },
            .text => null,
        };
    }

    pub fn getId(self: Element) ?[]const u8 {
        return switch (self) {
            .base => |base| {
                if (base.props) |props| {
                    return props.id;
                }
                return null;
            },
            .text => null,
        };
    }

    pub fn getClass(self: Element) ?[]const u8 {
        return switch (self) {
            .base => |base| {
                if (base.props) |props| {
                    return props.class;
                }
                return null;
            },
            .text => null,
        };
    }

    pub fn getText(self: Element) ?[]const u8 {
        return switch (self) {
            .text => |text| text,
            .base => null,
        };
    }
};

// Helper type for element children
pub const Children = ?[]const Element;

// Options struct for element creation
pub const ElementOpts = struct {
    props: ?Props = null,
    children: ?[]const Element = null,
};

fn writeAttr(buf: *std.ArrayList(u8), allocator: std.mem.Allocator, name: []const u8, value: []const u8) !void {
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

    pub fn render(self: ARIAProps, buf: *std.ArrayList(u8), allocator: std.mem.Allocator) !void {
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

        for (props) |prop| {
            if (prop.value) |value| {
                try writeAttr(buf, allocator, prop.name, value);
            }
        }
    }
};

// DOM properties for HTML elements
// Currently doesn't support data- props
pub const Props = struct {
    alt: ?Str = null,
    aria: ?ARIAProps = null,
    class: ?Str = null,
    charset: ?Str = null,
    checked: ?bool = null,
    content: ?Str = null,
    disabled: ?bool = null,
    height: ?u32 = null,
    href: ?Str = null,
    hx: ?HTMXProps = null,
    id: ?Str = null,
    lang: ?Str = null,
    name: ?Str = null,
    rel: ?Str = null,
    selected: ?bool = null,
    src: ?Str = null,
    style: ?Str = null,
    title: ?Str = null,
    type: ?Str = null,
    value: ?Str = null,
    width: ?u32 = null,

    pub fn render(self: Props, buf: *std.ArrayList(u8), allocator: std.mem.Allocator) !void {
        if (self.aria) |aria| {
            try aria.render(buf, allocator);
        }
        if (self.hx) |hx| {
            try hx.render(buf, allocator);
        }

        const string_props = [_]struct { name: []const u8, value: ?Str }{
            .{ .name = "alt", .value = self.alt },
            .{ .name = "class", .value = self.class },
            .{ .name = "charset", .value = self.charset },
            .{ .name = "content", .value = self.content },
            .{ .name = "href", .value = self.href },
            .{ .name = "id", .value = self.id },
            .{ .name = "lang", .value = self.lang },
            .{ .name = "name", .value = self.name },
            .{ .name = "rel", .value = self.rel },
            .{ .name = "src", .value = self.src },
            .{ .name = "style", .value = self.style },
            .{ .name = "title", .value = self.title },
            .{ .name = "type", .value = self.type },
            .{ .name = "value", .value = self.value },
        };

        for (string_props) |prop| {
            if (prop.value) |value| {
                try writeAttr(buf, allocator, prop.name, value);
            }
        }

        if (self.checked) |checked| {
            if (checked) {
                try writeAttr(buf, allocator, "checked", "checked");
            }
        }

        if (self.disabled) |disabled| {
            if (disabled) {
                try writeAttr(buf, allocator, "disabled", "disabled");
            }
        }

        if (self.selected) |selected| {
            if (selected) {
                try writeAttr(buf, allocator, "selected", "selected");
            }
        }

        if (self.height) |height| {
            var num_buf: [16]u8 = undefined;
            const num_str = std.fmt.bufPrint(&num_buf, "{d}", .{height}) catch unreachable;
            try writeAttr(buf, allocator, "height", num_str);
        }

        if (self.width) |width| {
            var num_buf: [16]u8 = undefined;
            const num_str = std.fmt.bufPrint(&num_buf, "{d}", .{width}) catch unreachable;
            try writeAttr(buf, allocator, "width", num_str);
        }
    }
};

const TagCache = struct {
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
};

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
        if (std.mem.eql(u8, self.tag, "html")) {
            const doctype = if (compact) "<!DOCTYPE html><html" else "<!DOCTYPE html>\n<html";
            try buf.appendSlice(allocator, doctype);
        } else {
            if (getTagFromCache(self.tag)) |cached| {
                try buf.appendSlice(allocator, cached.open_prefix);
            } else {
                try buf.appendSlice(allocator, "<");
                try buf.appendSlice(allocator, self.tag);
            }
        }

        if (self.props) |props| {
            try props.render(buf, allocator);
        }

        try buf.appendSlice(allocator, ">");
        if (!compact) {
            try buf.appendSlice(allocator, "\n");
        }

        if (self.children) |children| {
            for (children) |child| {
                try child.render(buf, allocator, compact);
            }
        }

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

fn estimateSize(element: Element, compact: bool) usize {
    return switch (element) {
        .text => |text| text.len,
        .base => |base| estimateBaseTagSize(base, compact),
    };
}

fn estimateBaseTagSize(tag: BaseTag, compact: bool) usize {
    var size: usize = 0;

    if (std.mem.eql(u8, tag.tag, "html")) {
        size += if (compact) 15 else 16;
    }

    size += 2 + tag.tag.len;

    if (tag.props) |props| {
        size += estimatePropsSize(props);
    }

    size += 1;
    if (!compact) size += 1;

    if (tag.children) |children| {
        for (children) |child| {
            size += estimateSize(child, compact);
        }
    }

    size += 3 + tag.tag.len;
    if (!compact) size += 1;

    return size;
}

fn estimatePropsSize(props: Props) usize {
    var size: usize = 0;

    inline for (@typeInfo(Props).@"struct".fields) |field| {
        const value = @field(props, field.name);
        if (field.type == ?Str) {
            if (value) |v| {
                size += 4 + field.name.len + v.len;
            }
        } else if (field.type == ?ARIAProps) {
            if (value) |aria| {
                inline for (@typeInfo(ARIAProps).@"struct".fields) |aria_field| {
                    const aria_value = @field(aria, aria_field.name);
                    if (aria_value) |v| {
                        size += 9 + aria_field.name.len + v.len;
                    }
                }
            }
        } else if (field.type == ?HTMXProps) {
            if (value) |hx| {
                inline for (@typeInfo(HTMXProps).@"struct".fields) |hx_field| {
                    const hx_value = @field(hx, hx_field.name);
                    if (hx_value) |v| {
                        size += 7 + hx_field.name.len + v.len;
                    }
                }
            }
        }
    }

    return size;
}

pub const Builder = struct {
    allocator: std.mem.Allocator,
    string_allocations: std.ArrayList([]u8),
    element_allocations: std.ArrayList([]Element),

    pub fn init(allocator: std.mem.Allocator) Builder {
        return Builder{
            .allocator = allocator,
            .string_allocations = std.ArrayList([]u8){},
            .element_allocations = std.ArrayList([]Element){},
        };
    }

    pub fn deinit(self: *Builder) void {
        for (self.string_allocations.items) |allocation| {
            self.allocator.free(allocation);
        }
        self.string_allocations.deinit(self.allocator);

        for (self.element_allocations.items) |allocation| {
            self.allocator.free(allocation);
        }
        self.element_allocations.deinit(self.allocator);
    }

    pub fn text(self: *Builder, content: Str) Element {
        const copy = self.allocator.dupe(u8, content) catch unreachable;
        self.string_allocations.append(self.allocator, copy) catch unreachable;
        return Element{ .text = copy };
    }

    pub fn renderToString(self: *Builder, element: Element, compact: bool) ![]u8 {
        const estimated_size = estimateSize(element, compact);
        const initial_capacity = @max(estimated_size, INITIAL_BUFFER_SIZE);

        var buf = try std.ArrayList(u8).initCapacity(self.allocator, initial_capacity);
        try element.render(&buf, self.allocator, compact);
        return buf.toOwnedSlice(self.allocator);
    }

    fn baseElementConfig(self: *Builder, tag: Str, props: ?Props, children: Children) BaseTag {
        const tagCopy = self.allocator.dupe(u8, tag) catch unreachable;
        self.string_allocations.append(self.allocator, tagCopy) catch unreachable;

        var childrenCopy: ?[]const Element = null;
        if (children) |c| {
            const elCopy = self.allocator.dupe(Element, c) catch unreachable;
            self.element_allocations.append(self.allocator, elCopy) catch unreachable;
            childrenCopy = elCopy;
        }

        return BaseTag{ .tag = tagCopy, .children = childrenCopy, .props = props };
    }

    pub fn html(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "html", opts.props, opts.children).el();
    }

    pub fn a(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "a", opts.props, opts.children).el();
    }

    pub fn b(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "b", opts.props, opts.children).el();
    }

    pub fn body(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "body", opts.props, opts.children).el();
    }

    pub fn div(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "div", opts.props, opts.children).el();
    }

    pub fn h1(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "h1", opts.props, opts.children).el();
    }

    pub fn h2(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "h2", opts.props, opts.children).el();
    }

    pub fn h3(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "h3", opts.props, opts.children).el();
    }

    pub fn h4(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "h4", opts.props, opts.children).el();
    }

    pub fn h5(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "h5", opts.props, opts.children).el();
    }

    pub fn h6(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "h6", opts.props, opts.children).el();
    }

    pub fn head(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "head", opts.props, opts.children).el();
    }

    pub fn hr(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "hr", opts.props, opts.children).el();
    }

    pub fn i(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "i", opts.props, opts.children).el();
    }

    pub fn img(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "img", opts.props, opts.children).el();
    }

    pub fn li(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "li", opts.props, opts.children).el();
    }

    pub fn link(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "link", opts.props, opts.children).el();
    }

    pub fn meta(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "meta", opts.props, opts.children).el();
    }

    pub fn nav(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "nav", opts.props, opts.children).el();
    }

    pub fn ol(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "ol", opts.props, opts.children).el();
    }

    pub fn p(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "p", opts.props, opts.children).el();
    }

    pub fn script(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "script", opts.props, opts.children).el();
    }

    pub fn span(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "span", opts.props, opts.children).el();
    }

    pub fn table(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "table", opts.props, opts.children).el();
    }

    pub fn td(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "td", opts.props, opts.children).el();
    }

    pub fn th(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "th", opts.props, opts.children).el();
    }

    pub fn title(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "title", opts.props, opts.children).el();
    }

    pub fn tr(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "tr", opts.props, opts.children).el();
    }

    pub fn ul(self: *Builder, opts: ElementOpts) Element {
        return baseElementConfig(self, "ul", opts.props, opts.children).el();
    }
};
