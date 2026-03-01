const std = @import("std");
const core = @import("html_core.zig");

pub const Str = core.Str;
const INITIAL_BUFFER_SIZE = core.INITIAL_BUFFER_SIZE;
pub const RenderError = core.RenderError;
const escapeHtml = core.escapeHtml;

/// HTML element - either a text node or a DOM element with tag, props, and children.
///
/// Text nodes are automatically HTML-escaped during rendering to prevent XSS.
/// Use Element.render() to convert to HTML string.
pub const Element = union(enum) {
    base: BaseTag,
    text: []u8,
    unsafe_text: []u8,
    /// Borrowed string (e.g. a string literal) — HTML-escaped on render, never freed.
    static_text: []const u8,

    fn isText(self: Element) bool {
        return switch (self) {
            .text, .unsafe_text, .static_text => true,
            else => false,
        };
    }

    pub fn render(self: Element, buf: *std.ArrayList(u8), allocator: std.mem.Allocator, compact: bool) std.mem.Allocator.Error!void {
        switch (self) {
            .base => |base| try base.render(buf, allocator, compact),
            .text => |text| try core.escapeHtmlToBuffer(buf, allocator, text),
            .unsafe_text => |text| try buf.appendSlice(allocator, text),
            .static_text => |text| try core.escapeHtmlToBuffer(buf, allocator, text),
        }
    }

    /// Render element directly to a Writer for streaming output.
    ///
    /// This method avoids allocating a full buffer, making it suitable for
    /// large templates or when streaming to a network socket or file.
    ///
    /// Arguments:
    ///     writer: Any type with a write() method (e.g., std.fs.File.Writer)
    ///     allocator: Allocator for temporary escape buffers
    ///     compact: If true, omit newlines and unnecessary whitespace
    ///
    /// Example:
    ///     const file = try std.fs.cwd().createFile("output.html", .{});
    ///     defer file.close();
    ///     try element.renderToWriter(file.writer(), allocator, false);
    pub fn renderToWriter(self: Element, writer: anytype, allocator: std.mem.Allocator, compact: bool) (@TypeOf(writer).Error || std.mem.Allocator.Error)!void {
        switch (self) {
            .base => |base| try base.renderToWriter(writer, allocator, compact),
            .text => |text| {
                const escaped = try escapeHtml(allocator, text);
                defer allocator.free(escaped);
                try writer.writeAll(escaped);
            },
            .unsafe_text => |text| try writer.writeAll(text),
            .static_text => |text| {
                const escaped = try escapeHtml(allocator, text);
                defer allocator.free(escaped);
                try writer.writeAll(escaped);
            },
        }
    }

    // Helper methods to reduce optional chaining
    pub fn getTag(self: Element) ?[]const u8 {
        return switch (self) {
            .base => |base| base.tag,
            .text, .unsafe_text, .static_text => null,
        };
    }

    pub fn getProps(self: Element) ?Props {
        return switch (self) {
            .base => |base| base.props,
            .text, .unsafe_text, .static_text => null,
        };
    }

    pub fn getChildren(self: Element) ?[]const Element {
        return switch (self) {
            .base => |base| base.children,
            .text, .unsafe_text, .static_text => null,
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
            .text, .unsafe_text, .static_text => null,
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
            .text, .unsafe_text, .static_text => null,
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
            .text, .unsafe_text, .static_text => null,
        };
    }

    pub fn getText(self: Element) ?[]const u8 {
        return switch (self) {
            .text => |text| text,
            .unsafe_text => |text| text,
            .static_text => |text| text,
            .base => null,
        };
    }
};

/// Create a text node from a string literal without allocating.
///
/// The string is HTML-escaped during rendering. The caller is responsible
/// for ensuring `str` outlives the element tree — string literals always
/// satisfy this requirement.
///
/// Contrast with `Builder.text()`, which copies the string and is
/// appropriate for runtime strings (e.g. values from a database query).
///
/// Example:
///     .children = &[_]Element{ ztl.t("Hello, world!") }
pub fn t(str: []const u8) Element {
    return .{ .static_text = str };
}

// Helper type for element children
pub const Children = ?[]const Element;

/// Content union for ergonomic text or element specification.
///
/// Allows passing either a text string or an array of elements.
/// When using .text, the content is automatically wrapped in a text node.
///
/// Example:
///     .content = .{ .text = "Hello" }
///     .content = .{ .elements = &[_]Element{...} }
pub const Content = union(enum) {
    text: []const u8,
    elements: []const Element,
};

/// Options for creating HTML elements.
///
/// Supports three ways to specify content:
/// 1. .children - Traditional array of elements
/// 2. .content = .{ .text = "..." } - Ergonomic text content
/// 3. .content = .{ .elements = &[_]Element{...} } - Alternative to children
///
/// Example:
///     .{ .props = .{ .class = "container" }, .content = .{ .text = "Hello" } }
pub const ElementOpts = struct {
    props: ?Props = null,
    children: ?[]const Element = null,
    content: ?Content = null,
};

const writeAttr = core.writeAttr;

pub const ARIAProps = core.ARIAProps;
pub const HTMXProps = core.HTMXProps;

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

    /// Optimization: Inline to reduce function call overhead on hot path
    pub inline fn render(self: Props, buf: *std.ArrayList(u8), allocator: std.mem.Allocator) std.mem.Allocator.Error!void {
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

const getTagFromCache = core.getTagFromCache;

pub const BaseTag = struct {
    tag: Str,
    children: Children,
    props: ?Props = null,

    pub fn render(self: BaseTag, buf: *std.ArrayList(u8), allocator: std.mem.Allocator, compact: bool) std.mem.Allocator.Error!void {
        try core.renderOpenTag(buf, allocator, self.tag, self.props, compact);

        if (self.children) |children| {
            for (children) |child| {
                try child.render(buf, allocator, compact);
            }
        }

        try core.renderCloseTag(buf, allocator, self.tag, compact);
    }

    pub fn renderToWriter(self: BaseTag, writer: anytype, allocator: std.mem.Allocator, compact: bool) (@TypeOf(writer).Error || std.mem.Allocator.Error)!void {
        try core.renderOpenTagToWriter(writer, allocator, self.tag, self.props, compact);

        if (self.children) |children| {
            for (children) |child| {
                try child.renderToWriter(writer, allocator, compact);
            }
        }

        try core.renderCloseTagToWriter(writer, self.tag, compact);
    }

    pub fn el(self: BaseTag) Element {
        return Element{ .base = self };
    }
};

fn estimateSize(element: Element, compact: bool) usize {
    return switch (element) {
        // Optimization: Assume 12.5% overhead for HTML escaping instead of 100%
        // Most text has <5% special chars, but we add safety margin
        .text, .static_text => |text| text.len + (text.len / 8),
        .unsafe_text => |text| text.len,
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
                // attr format: space + name + ="value"
                size += 4 + field.name.len + v.len;
            }
        } else if (field.type == ?bool) {
            // Boolean props like checked="checked" when true
            if (value) |val| {
                if (val) {
                    // space + name + ="name"
                    size += 4 + field.name.len + field.name.len;
                }
            }
        } else if (field.type == ?u32) {
            // Numeric props need ~10 chars max for u32 value
            if (value) |_| {
                size += 4 + field.name.len + 10;
            }
        } else if (field.type == ?ARIAProps) {
            if (value) |aria| {
                inline for (@typeInfo(ARIAProps).@"struct".fields) |aria_field| {
                    const aria_value = @field(aria, aria_field.name);
                    if (aria_value) |v| {
                        // aria-* prefix (5 chars) + name + ="value"
                        size += 9 + aria_field.name.len + v.len;
                    }
                }
            }
        } else if (field.type == ?HTMXProps) {
            if (value) |hx| {
                inline for (@typeInfo(HTMXProps).@"struct".fields) |hx_field| {
                    const hx_value = @field(hx, hx_field.name);
                    if (hx_value) |v| {
                        // hx-* prefix (3 chars) + name + ="value"
                        size += 7 + hx_field.name.len + v.len;
                    }
                }
            }
        }
    }

    return size;
}

/// HTML element builder that manages memory allocations automatically.
///
/// The builder tracks all string and element array allocations made during
/// element construction. Call `deinit()` when done to free all tracked memory.
///
/// Example:
///     var builder = ztl.Builder.init(allocator);
///     defer builder.deinit();
///
///     const elem = try builder.div(.{
///         .props = .{ .class = "container" },
///         .content = .{ .text = "Hello" },
///     });
pub const Builder = struct {
    allocator: std.mem.Allocator,
    string_allocations: std.ArrayList([]u8),
    element_allocations: std.ArrayList([]Element),

    /// Initialize a new builder with the given allocator.
    /// The builder will track all allocations made during element construction.
    pub fn init(allocator: std.mem.Allocator) Builder {
        return Builder{
            .allocator = allocator,
            .string_allocations = std.ArrayList([]u8){},
            .element_allocations = std.ArrayList([]Element){},
        };
    }

    /// Free all tracked allocations.
    /// After calling this, all elements created by this builder become invalid.
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

    /// Create a text node with automatic HTML escaping.
    ///
    /// Common HTML entities (<, >, &, ", ') are escaped to prevent XSS vulnerabilities.
    /// The content string is copied and tracked for cleanup.
    ///
    /// Example:
    ///     const text = try builder.text("<script>alert('xss')</script>");
    ///     // Renders as: &lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;
    pub fn text(self: *Builder, content: Str) !Element {
        const copy = try self.allocator.dupe(u8, content);
        try self.string_allocations.append(self.allocator, copy);
        return Element{ .text = copy };
    }

    /// Create pre-escaped HTML content without entity escaping.
    ///
    /// Use only for trusted sources like markdown renderers or sanitized HTML.
    /// Does NOT escape HTML entities - content is rendered as-is.
    ///
    /// WARNING: Passing user input to this function creates XSS vulnerabilities.
    ///
    /// Example:
    ///     const html = try builder.unsafeText("<em>already</em> escaped");
    ///     // Renders as: <em>already</em> escaped
    pub fn unsafeText(self: *Builder, content: Str) !Element {
        const copy = try self.allocator.dupe(u8, content);
        try self.string_allocations.append(self.allocator, copy);
        return Element{ .unsafe_text = copy };
    }

    /// Render an element to a string.
    ///
    /// Allocates and returns a string containing the rendered HTML.
    /// Caller owns the returned memory and must free it.
    ///
    /// Arguments:
    ///     element: The element to render
    ///     compact: If true, omit newlines and unnecessary whitespace
    ///
    /// Example:
    ///     const html = try builder.renderToString(element, false);
    ///     defer allocator.free(html);
    pub fn renderToString(self: *Builder, element: Element, compact: bool) ![]u8 {
        const estimated_size = estimateSize(element, compact);
        const initial_capacity = @max(estimated_size, INITIAL_BUFFER_SIZE);

        var buf = try std.ArrayList(u8).initCapacity(self.allocator, initial_capacity);
        try element.render(&buf, self.allocator, compact);
        return buf.toOwnedSlice(self.allocator);
    }

    fn baseElementConfig(self: *Builder, tag: Str, props: ?Props, children: Children) !BaseTag {
        var childrenCopy: ?[]const Element = null;
        if (children) |c| {
            const elCopy = try self.allocator.dupe(Element, c);
            try self.element_allocations.append(self.allocator, elCopy);
            childrenCopy = elCopy;
        }

        return BaseTag{ .tag = tag, .children = childrenCopy, .props = props };
    }

    fn resolveChildren(self: *Builder, opts: ElementOpts) !?[]const Element {
        if (opts.content) |c| {
            return switch (c) {
                .text => |txt| blk: {
                    const slice = try self.allocator.alloc(Element, 1);
                    slice[0] = .{ .static_text = txt };
                    try self.element_allocations.append(self.allocator, slice);
                    break :blk slice;
                },
                .elements => |els| els,
            };
        }
        return opts.children;
    }

    pub fn html(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "html", opts.props, children)).el();
    }

    pub fn a(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "a", opts.props, children)).el();
    }

    pub fn b(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "b", opts.props, children)).el();
    }

    pub fn body(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "body", opts.props, children)).el();
    }

    pub fn div(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "div", opts.props, children)).el();
    }

    pub fn h1(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "h1", opts.props, children)).el();
    }

    pub fn h2(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "h2", opts.props, children)).el();
    }

    pub fn h3(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "h3", opts.props, children)).el();
    }

    pub fn h4(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "h4", opts.props, children)).el();
    }

    pub fn h5(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "h5", opts.props, children)).el();
    }

    pub fn h6(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "h6", opts.props, children)).el();
    }

    pub fn head(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "head", opts.props, children)).el();
    }

    pub fn hr(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "hr", opts.props, children)).el();
    }

    pub fn i(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "i", opts.props, children)).el();
    }

    pub fn img(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "img", opts.props, children)).el();
    }

    pub fn li(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "li", opts.props, children)).el();
    }

    pub fn link(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "link", opts.props, children)).el();
    }

    pub fn meta(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "meta", opts.props, children)).el();
    }

    pub fn nav(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "nav", opts.props, children)).el();
    }

    pub fn ol(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "ol", opts.props, children)).el();
    }

    pub fn p(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "p", opts.props, children)).el();
    }

    pub fn script(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "script", opts.props, children)).el();
    }

    pub fn span(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "span", opts.props, children)).el();
    }

    pub fn table(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "table", opts.props, children)).el();
    }

    pub fn td(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "td", opts.props, children)).el();
    }

    pub fn th(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "th", opts.props, children)).el();
    }

    pub fn title(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "title", opts.props, children)).el();
    }

    pub fn tr(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "tr", opts.props, children)).el();
    }

    pub fn ul(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "ul", opts.props, children)).el();
    }

    pub fn article(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "article", opts.props, children)).el();
    }

    pub fn aside(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "aside", opts.props, children)).el();
    }

    pub fn blockquote(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "blockquote", opts.props, children)).el();
    }

    pub fn button(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "button", opts.props, children)).el();
    }

    pub fn cite(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "cite", opts.props, children)).el();
    }

    pub fn code(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "code", opts.props, children)).el();
    }

    pub fn fieldset(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "fieldset", opts.props, children)).el();
    }

    pub fn figcaption(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "figcaption", opts.props, children)).el();
    }

    pub fn figure(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "figure", opts.props, children)).el();
    }

    pub fn footer(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "footer", opts.props, children)).el();
    }

    pub fn form(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "form", opts.props, children)).el();
    }

    pub fn header(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "header", opts.props, children)).el();
    }

    pub fn input(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "input", opts.props, children)).el();
    }

    pub fn kbd(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "kbd", opts.props, children)).el();
    }

    pub fn label(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "label", opts.props, children)).el();
    }

    pub fn legend(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "legend", opts.props, children)).el();
    }

    pub fn main(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "main", opts.props, children)).el();
    }

    pub fn option(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "option", opts.props, children)).el();
    }

    pub fn pre(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "pre", opts.props, children)).el();
    }

    pub fn samp(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "samp", opts.props, children)).el();
    }

    pub fn section(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "section", opts.props, children)).el();
    }

    pub fn select(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "select", opts.props, children)).el();
    }

    pub fn textarea(self: *Builder, opts: ElementOpts) !Element {
        const children = try self.resolveChildren(opts);
        return (try baseElementConfig(self, "textarea", opts.props, children)).el();
    }
};

/// Builder variant that panics on allocation failure instead of returning errors.
///
/// Suitable for server-side rendering where OOM is fatal anyway. Eliminates
/// `try` from all element construction calls. Pair with an `ArenaAllocator`
/// for the simplest memory model — the arena handles cleanup and the builder
/// never needs `deinit`.
///
/// `renderToString` still returns `![]u8` so HTTP handlers can propagate errors.
///
/// Example:
///     var arena = std.heap.ArenaAllocator.init(gpa);
///     defer arena.deinit();
///     var z = ztl.PanicBuilder.init(arena.allocator());
///
///     const page = z.html(.{
///         .props = .{ .lang = "en-US" },
///         .children = &.{
///             z.body(.{ .children = &.{
///                 z.h1(.{ .content = .{ .text = "Hello" } }),
///                 z.p(.{ .content = .{ .text = "World" } }),
///             } }),
///         },
///     });
pub const PanicBuilder = struct {
    inner: Builder,

    pub fn init(allocator: std.mem.Allocator) PanicBuilder {
        return .{ .inner = Builder.init(allocator) };
    }

    pub fn deinit(self: *PanicBuilder) void {
        self.inner.deinit();
    }

    pub fn renderToString(self: *PanicBuilder, element: Element, compact: bool) ![]u8 {
        return self.inner.renderToString(element, compact);
    }

    pub fn text(self: *PanicBuilder, content: Str) Element {
        return self.inner.text(content) catch @panic("out of memory");
    }

    pub fn unsafeText(self: *PanicBuilder, content: Str) Element {
        return self.inner.unsafeText(content) catch @panic("out of memory");
    }

    pub fn html(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.html(opts) catch @panic("out of memory");
    }

    pub fn a(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.a(opts) catch @panic("out of memory");
    }

    pub fn b(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.b(opts) catch @panic("out of memory");
    }

    pub fn body(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.body(opts) catch @panic("out of memory");
    }

    pub fn div(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.div(opts) catch @panic("out of memory");
    }

    pub fn h1(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.h1(opts) catch @panic("out of memory");
    }

    pub fn h2(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.h2(opts) catch @panic("out of memory");
    }

    pub fn h3(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.h3(opts) catch @panic("out of memory");
    }

    pub fn h4(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.h4(opts) catch @panic("out of memory");
    }

    pub fn h5(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.h5(opts) catch @panic("out of memory");
    }

    pub fn h6(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.h6(opts) catch @panic("out of memory");
    }

    pub fn head(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.head(opts) catch @panic("out of memory");
    }

    pub fn hr(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.hr(opts) catch @panic("out of memory");
    }

    pub fn i(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.i(opts) catch @panic("out of memory");
    }

    pub fn img(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.img(opts) catch @panic("out of memory");
    }

    pub fn li(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.li(opts) catch @panic("out of memory");
    }

    pub fn link(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.link(opts) catch @panic("out of memory");
    }

    pub fn meta(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.meta(opts) catch @panic("out of memory");
    }

    pub fn nav(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.nav(opts) catch @panic("out of memory");
    }

    pub fn ol(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.ol(opts) catch @panic("out of memory");
    }

    pub fn p(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.p(opts) catch @panic("out of memory");
    }

    pub fn script(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.script(opts) catch @panic("out of memory");
    }

    pub fn span(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.span(opts) catch @panic("out of memory");
    }

    pub fn table(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.table(opts) catch @panic("out of memory");
    }

    pub fn td(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.td(opts) catch @panic("out of memory");
    }

    pub fn th(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.th(opts) catch @panic("out of memory");
    }

    pub fn title(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.title(opts) catch @panic("out of memory");
    }

    pub fn tr(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.tr(opts) catch @panic("out of memory");
    }

    pub fn ul(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.ul(opts) catch @panic("out of memory");
    }

    pub fn article(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.article(opts) catch @panic("out of memory");
    }

    pub fn aside(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.aside(opts) catch @panic("out of memory");
    }

    pub fn blockquote(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.blockquote(opts) catch @panic("out of memory");
    }

    pub fn button(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.button(opts) catch @panic("out of memory");
    }

    pub fn cite(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.cite(opts) catch @panic("out of memory");
    }

    pub fn code(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.code(opts) catch @panic("out of memory");
    }

    pub fn fieldset(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.fieldset(opts) catch @panic("out of memory");
    }

    pub fn figcaption(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.figcaption(opts) catch @panic("out of memory");
    }

    pub fn figure(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.figure(opts) catch @panic("out of memory");
    }

    pub fn footer(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.footer(opts) catch @panic("out of memory");
    }

    pub fn form(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.form(opts) catch @panic("out of memory");
    }

    pub fn header(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.header(opts) catch @panic("out of memory");
    }

    pub fn input(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.input(opts) catch @panic("out of memory");
    }

    pub fn kbd(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.kbd(opts) catch @panic("out of memory");
    }

    pub fn label(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.label(opts) catch @panic("out of memory");
    }

    pub fn legend(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.legend(opts) catch @panic("out of memory");
    }

    pub fn main(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.main(opts) catch @panic("out of memory");
    }

    pub fn option(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.option(opts) catch @panic("out of memory");
    }

    pub fn pre(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.pre(opts) catch @panic("out of memory");
    }

    pub fn samp(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.samp(opts) catch @panic("out of memory");
    }

    pub fn section(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.section(opts) catch @panic("out of memory");
    }

    pub fn select(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.select(opts) catch @panic("out of memory");
    }

    pub fn textarea(self: *PanicBuilder, opts: ElementOpts) Element {
        return self.inner.textarea(opts) catch @panic("out of memory");
    }
};
