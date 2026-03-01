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
    text: []const u8,
    unsafe_text: []const u8,

    fn isText(self: Element) bool {
        return switch (self) {
            .text, .unsafe_text => true,
            else => false,
        };
    }

    pub fn render(self: Element, buf: *std.ArrayList(u8), allocator: std.mem.Allocator, compact: bool) std.mem.Allocator.Error!void {
        switch (self) {
            .base => |base| try base.render(buf, allocator, compact),
            .text => |text| try core.escapeHtmlToBuffer(buf, allocator, text),
            .unsafe_text => |text| try buf.appendSlice(allocator, text),
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
        }
    }
};

// Helper type for element children
pub const Children = ?[]const Element;

/// Content union for ergonomic text or element specification.
///
/// Allows passing either a text string or an array of elements.
/// This type is defined for API consistency with ztl.zig.
/// For ztlc.zig, prefer using the direct parameter API (props, children).
pub const Content = union(enum) {
    text: []const u8,
    elements: []const Element,
};

/// Element configuration with content support.
///
/// This type is defined for API consistency with ztl.zig.
/// For ztlc.zig, prefer using the direct parameter API (props, children).
pub const ElementConfig = struct {
    props: ?Props = null,
    content: ?Content = null,
};

const writeAttr = core.writeAttr;

pub const ARIAProps = core.ARIAProps;
pub const HTMXProps = core.HTMXProps;

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

    /// Optimization: Inline to reduce function call overhead on hot path
    pub inline fn render(self: Props, buf: *std.ArrayList(u8), allocator: std.mem.Allocator) std.mem.Allocator.Error!void {
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
        .text => |text| text.len + (text.len / 8),
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

/// HTML element builder with direct parameter API and comptime tag caching.
///
/// This is the performance-optimized variant of the builder.
/// Use element functions with direct (props, children) parameters.
/// The builder tracks allocations automatically. Call `deinit()` when done.
///
/// Example:
///     var builder = ztlc.Builder.init(allocator);
///     defer builder.deinit();
///
///     const elem = try builder.div(.{ .class = "container" }, &[_]Element{
///         try builder.text("Hello"),
///     });
pub const Builder = struct {
    allocator: std.mem.Allocator,
    string_allocations: std.ArrayList([]u8),
    element_allocations: std.ArrayList([]Element),
    copy_literals: bool,

    /// Initialize a new builder with the given allocator.
    /// The builder will track all allocations made during element construction.
    pub fn init(allocator: std.mem.Allocator) Builder {
        return Builder{
            .allocator = allocator,
            .string_allocations = std.ArrayList([]u8){},
            .element_allocations = std.ArrayList([]Element){},
            .copy_literals = false,
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
    /// The content string is copied if copy_literals is true.
    ///
    /// Example:
    ///     const text = try builder.text("<script>alert('xss')</script>");
    ///     // Renders as: &lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;
    pub fn text(self: *Builder, content: Str) !Element {
        if (self.copy_literals) {
            const copy = try self.allocator.dupe(u8, content);
            try self.string_allocations.append(self.allocator, copy);
            return Element{ .text = copy };
        } else {
            return Element{ .text = content };
        }
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
        if (self.copy_literals) {
            const copy = try self.allocator.dupe(u8, content);
            try self.string_allocations.append(self.allocator, copy);
            return Element{ .unsafe_text = copy };
        } else {
            return Element{ .unsafe_text = content };
        }
    }

    fn baseElementConfig(self: *Builder, tag: Str, props: ?Props, children: Children) !BaseTag {
        var tagToUse = tag;

        if (self.copy_literals) {
            const tagCopy = try self.allocator.dupe(u8, tag);
            try self.string_allocations.append(self.allocator, tagCopy);
            tagToUse = tagCopy;
        }

        var childrenCopy: ?[]const Element = null;
        if (children) |c| {
            const elCopy = try self.allocator.dupe(Element, c);
            try self.element_allocations.append(self.allocator, elCopy);
            childrenCopy = elCopy;
        }

        return BaseTag{ .tag = tagToUse, .children = childrenCopy, .props = props };
    }

    /// Render an element to a string.
    ///
    /// Allocates and returns a string containing the rendered HTML.
    /// Caller owns the returned memory and must free it.
    ///
    /// Arguments:
    ///     root: The element to render
    ///     compact: If true, omit newlines and unnecessary whitespace
    ///
    /// Example:
    ///     const html = try builder.renderToString(element, false);
    ///     defer allocator.free(html);
    pub fn renderToString(self: *Builder, root: Element, compact: bool) ![]u8 {
        const estimated_size = estimateSize(root, compact);
        const initial_capacity = @max(estimated_size, INITIAL_BUFFER_SIZE);
        
        var buf = try std.ArrayList(u8).initCapacity(self.allocator, initial_capacity);
        try root.render(&buf, self.allocator, compact);
        return buf.toOwnedSlice(self.allocator);
    }

    pub fn html(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("html", props, children)).el();
    }

    pub fn a(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("a", props, children)).el();
    }

    pub fn b(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("b", props, children)).el();
    }

    pub fn body(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("body", props, children)).el();
    }

    pub fn div(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("div", props, children)).el();
    }

    pub fn h1(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("h1", props, children)).el();
    }

    pub fn h2(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("h2", props, children)).el();
    }

    pub fn h3(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("h3", props, children)).el();
    }

    pub fn h4(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("h4", props, children)).el();
    }

    pub fn h5(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("h5", props, children)).el();
    }

    pub fn h6(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("h6", props, children)).el();
    }

    pub fn head(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("head", props, children)).el();
    }

    pub fn hr(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("hr", props, children)).el();
    }

    pub fn i(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("i", props, children)).el();
    }

    pub fn img(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("img", props, children)).el();
    }

    pub fn li(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("li", props, children)).el();
    }

    pub fn link(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("link", props, children)).el();
    }

    pub fn meta(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("meta", props, children)).el();
    }

    pub fn nav(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("nav", props, children)).el();
    }

    pub fn ol(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("ol", props, children)).el();
    }

    pub fn p(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("p", props, children)).el();
    }

    pub fn script(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("script", props, children)).el();
    }

    pub fn span(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("span", props, children)).el();
    }

    pub fn table(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("table", props, children)).el();
    }

    pub fn td(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("td", props, children)).el();
    }

    pub fn th(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("th", props, children)).el();
    }

    pub fn title(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("title", props, children)).el();
    }

    pub fn tr(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("tr", props, children)).el();
    }

    pub fn ul(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("ul", props, children)).el();
    }

    pub fn article(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("article", props, children)).el();
    }

    pub fn aside(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("aside", props, children)).el();
    }

    pub fn blockquote(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("blockquote", props, children)).el();
    }

    pub fn button(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("button", props, children)).el();
    }

    pub fn cite(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("cite", props, children)).el();
    }

    pub fn code(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("code", props, children)).el();
    }

    pub fn fieldset(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("fieldset", props, children)).el();
    }

    pub fn figcaption(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("figcaption", props, children)).el();
    }

    pub fn figure(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("figure", props, children)).el();
    }

    pub fn footer(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("footer", props, children)).el();
    }

    pub fn form(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("form", props, children)).el();
    }

    pub fn header(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("header", props, children)).el();
    }

    pub fn input(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("input", props, children)).el();
    }

    pub fn kbd(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("kbd", props, children)).el();
    }

    pub fn label(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("label", props, children)).el();
    }

    pub fn legend(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("legend", props, children)).el();
    }

    pub fn main(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("main", props, children)).el();
    }

    pub fn option(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("option", props, children)).el();
    }

    pub fn pre(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("pre", props, children)).el();
    }

    pub fn samp(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("samp", props, children)).el();
    }

    pub fn section(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("section", props, children)).el();
    }

    pub fn select(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("select", props, children)).el();
    }

    pub fn textarea(self: *Builder, props: ?Props, children: Children) !Element {
        return (try self.baseElementConfig("textarea", props, children)).el();
    }
};
