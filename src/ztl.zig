const std = @import("std");

// Helper type for string literal
pub const Str = []const u8;

// HTML elements are either text or DOM objects
pub const Element = union(enum) {
    base: BaseTag,
    text: []u8,

    fn isText(self: Element) bool {
        return switch (self) {
            self.text => true,
            else => false,
        };
    }

    pub fn render(self: Element, buf: *std.ArrayList(u8), compact: bool) !void {
        switch (self) {
            .base => |base| try base.render(buf, compact),
            .text => |text| try buf.appendSlice(text),
        }
    }
};

// Helper type for element children
pub const Children = ?[]const Element;

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
        if (self.activedescendant) |ad| {
            try buf.appendSlice(" aria-activedescendent=\"");
            try buf.appendSlice(ad);
            try buf.appendSlice("\"");
        }
        if (self.checked) |checked| {
            try buf.appendSlice(" aria-checked=\"");
            try buf.appendSlice(checked);
            try buf.appendSlice("\"");
        }
        if (self.controls) |controls| {
            try buf.appendSlice(" aria-controls=\"");
            try buf.appendSlice(controls);
            try buf.appendSlice("\"");
        }
        if (self.describedby) |describedby| {
            try buf.appendSlice(" aria-describedby=\"");
            try buf.appendSlice(describedby);
            try buf.appendSlice("\"");
        }
        if (self.disabled) |disabled| {
            try buf.appendSlice(" aria-disabled=\"");
            try buf.appendSlice(disabled);
            try buf.appendSlice("\"");
        }
        if (self.expanded) |expanded| {
            try buf.appendSlice(" aria-expanded=\"");
            try buf.appendSlice(expanded);
            try buf.appendSlice("\"");
        }
        if (self.hidden) |hidden| {
            try buf.appendSlice(" aria-hidden=\"");
            try buf.appendSlice(hidden);
            try buf.appendSlice("\"");
        }
        if (self.label) |label| {
            try buf.appendSlice(" aria-label=\"");
            try buf.appendSlice(label);
            try buf.appendSlice("\"");
        }
        if (self.labelledby) |labelledby| {
            try buf.appendSlice(" aria-labelledby=\"");
            try buf.appendSlice(labelledby);
            try buf.appendSlice("\"");
        }
        if (self.live) |live| {
            try buf.appendSlice(" aria-live=\"");
            try buf.appendSlice(live);
            try buf.appendSlice("\"");
        }
        if (self.owns) |owns| {
            try buf.appendSlice(" aria-owns=\"");
            try buf.appendSlice(owns);
            try buf.appendSlice("\"");
        }
        if (self.pressed) |pressed| {
            try buf.appendSlice(" aria-pressed=\"");
            try buf.appendSlice(pressed);
            try buf.appendSlice("\"");
        }
        if (self.role) |role| {
            try buf.appendSlice(" aria-role=\"");
            try buf.appendSlice(role);
            try buf.appendSlice("\"");
        }
        if (self.selected) |selected| {
            try buf.appendSlice(" aria-selected=\"");
            try buf.appendSlice(selected);
            try buf.appendSlice("\"");
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

    // @TODO
    pub fn render(self: HTMXProps, buf: *std.ArrayList(u8)) !void {
        if (self.boost) |boost| {
            try buf.appendSlice(" hx-boost=\"");
            try buf.appendSlice(boost);
            try buf.appendSlice("\"");
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
        if (self.alt) |alt| {
            try buf.appendSlice(" alt=\"");
            try buf.appendSlice(alt);
            try buf.appendSlice("\"");
        }
        if (self.aria) |aria| {
            try aria.render(buf);
        }
        if (self.class) |class| {
            try buf.appendSlice(" class=\"");
            try buf.appendSlice(class);
            try buf.appendSlice("\"");
        }
        if (self.charset) |charset| {
            try buf.appendSlice(" charset=\"");
            try buf.appendSlice(charset);
            try buf.appendSlice("\"");
        }
        if (self.checked) |checked| {
            try buf.appendSlice(" checked=\"");
            try buf.appendSlice(checked);
            try buf.appendSlice("\"");
        }
        if (self.content) |content| {
            try buf.appendSlice(" content=\"");
            try buf.appendSlice(content);
            try buf.appendSlice("\"");
        }
        if (self.disabled) |disabled| {
            try buf.appendSlice(" disabled=\"");
            try buf.appendSlice(disabled);
            try buf.appendSlice("\"");
        }
        if (self.height) |height| {
            // use std.fmt.formatIntValue
            try buf.appendSlice(" height=\"");
            try buf.appendSlice(height);
            try buf.appendSlice("\"");
        }
        if (self.href) |href| {
            try buf.appendSlice(" href=\"");
            try buf.appendSlice(href);
            try buf.appendSlice("\"");
        }
        if (self.hx) |hx| {
            try hx.render(buf);
        }
        if (self.id) |id| {
            try buf.appendSlice(" id=\"");
            try buf.appendSlice(id);
            try buf.appendSlice("\"");
        }
        if (self.lang) |lang| {
            try buf.appendSlice(" lang=\"");
            try buf.appendSlice(lang);
            try buf.appendSlice("\"");
        }
        if (self.rel) |rel| {
            try buf.appendSlice(" rel=\"");
            try buf.appendSlice(rel);
            try buf.appendSlice("\"");
        }
        if (self.selected) |selected| {
            try buf.appendSlice(" selected=\"");
            try buf.appendSlice(selected);
            try buf.appendSlice("\"");
        }
        if (self.src) |src| {
            try buf.appendSlice(" src=\"");
            try buf.appendSlice(src);
            try buf.appendSlice("\"");
        }
        if (self.style) |style| {
            try buf.appendSlice(" style=\"");
            try buf.appendSlice(style);
            try buf.appendSlice("\"");
        }
        if (self.title) |t| {
            try buf.appendSlice(" title=\"");
            try buf.appendSlice(t);
            try buf.appendSlice("\"");
        }
        if (self.type) |t| {
            try buf.appendSlice(" type=\"");
            try buf.appendSlice(t);
            try buf.appendSlice("\"");
        }
        if (self.value) |value| {
            try buf.appendSlice(" value=\"");
            try buf.appendSlice(value);
            try buf.appendSlice("\"");
        }
        if (self.width) |width| {
            // @TODO: use std.fmt.formatIntValue
            try buf.appendSlice(" width=\"");
            try buf.appendSlice(width);
            try buf.appendSlice("\"");
        }
    }
};

pub const BaseTag = struct {
    tag: Str,
    children: Children,
    props: ?Props = null,

    pub fn render(self: BaseTag, buf: *std.ArrayList(u8), compact: bool) anyerror!void {
        if (std.mem.eql(u8, self.tag, "html")) {
            try buf.appendSlice("<!DOCTYPE html>");
            if (!compact) {
                try buf.appendSlice("\n");
            }
        }
        try buf.appendSlice("<");
        try buf.appendSlice(self.tag);
        if (self.props) |props| {
            try props.render(buf);
        }
        try buf.appendSlice(">");
        if (!compact) {
            try buf.appendSlice("\n");
        }

        if (self.children) |children| {
            for (children) |child| {
                try child.render(buf, compact);
            }
        }

        try buf.appendSlice("</");
        try buf.appendSlice(self.tag);
        try buf.appendSlice(">");
        if (!compact) {
            try buf.appendSlice("\n");
        }
    }

    pub fn el(self: BaseTag) Element {
        return Element{ .base = self };
    }
};

pub const ZTLBuilder = struct {
    allocator: std.mem.Allocator,
    // Track string allocations (for text content and tag names)
    string_allocations: std.ArrayList([]u8),
    // Track element array allocations
    element_allocations: std.ArrayList([]Element),

    pub fn init(allocator: std.mem.Allocator) ZTLBuilder {
        return ZTLBuilder{
            .allocator = allocator,
            .string_allocations = std.ArrayList([]u8).init(allocator),
            .element_allocations = std.ArrayList([]Element).init(allocator),
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

    pub fn text(self: *ZTLBuilder, content: Str) Element {
        const copy = self.allocator.dupe(u8, content) catch unreachable;
        self.string_allocations.append(copy) catch unreachable;
        return Element{ .text = copy };
    }

    fn baseElementConfig(self: *ZTLBuilder, tag: Str, props: ?Props, children: Children) BaseTag {
        // Allocate and track tag name
        const tagCopy = self.allocator.dupe(u8, tag) catch unreachable;
        self.string_allocations.append(tagCopy) catch unreachable;

        // Allocate and track children array if present
        var childrenCopy: ?[]const Element = null;
        if (children) |c| {
            const elCopy = self.allocator.dupe(Element, c) catch unreachable;
            self.element_allocations.append(elCopy) catch unreachable;
            childrenCopy = elCopy;
        }

        return BaseTag{ .tag = tagCopy, .children = childrenCopy, .props = props };
    }

    pub fn html(self: *ZTLBuilder, props: ?Props, children: Children) BaseTag {
        return baseElementConfig(self, "html", props, children);
    }

    pub fn a(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "a", props, children).el();
    }

    pub fn b(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "b", props, children).el();
    }

    pub fn body(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "body", props, children).el();
    }

    pub fn div(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "div", props, children).el();
    }

    pub fn h1(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "h1", props, children).el();
    }

    pub fn h2(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "h2", props, children).el();
    }

    pub fn h3(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "h3", props, children).el();
    }

    pub fn h4(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "h4", props, children).el();
    }

    pub fn h5(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "h5", props, children).el();
    }

    pub fn h6(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "h6", props, children).el();
    }

    pub fn head(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "head", props, children).el();
    }

    pub fn hr(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "hr", props, children).el();
    }

    pub fn i(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "i", props, children).el();
    }

    pub fn img(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "img", props, children).el();
    }

    pub fn li(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "li", props, children).el();
    }

    pub fn link(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "link", props, children).el();
    }

    pub fn meta(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "meta", props, children).el();
    }

    pub fn nav(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "nav", props, children).el();
    }

    pub fn ol(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "ol", props, children).el();
    }

    pub fn p(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "p", props, children).el();
    }

    pub fn script(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "script", props, children).el();
    }

    pub fn span(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "span", props, children).el();
    }

    pub fn table(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "table", props, children).el();
    }

    pub fn td(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "td", props, children).el();
    }

    pub fn th(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "th", props, children).el();
    }

    pub fn title(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "title", props, children).el();
    }

    pub fn tr(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "tr", props, children).el();
    }

    pub fn ul(self: *ZTLBuilder, props: ?Props, children: Children) Element {
        return baseElementConfig(self, "ul", props, children).el();
    }
};
