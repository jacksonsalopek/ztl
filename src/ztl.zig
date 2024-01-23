const std = @import("std");

// Helper type for string literal
pub const Str = []const u8;

// HTML elements are either text or DOM objects
pub const El = union(enum) {
    base: BaseTag,
    text: []u8,

    fn isText(self: El) bool {
        return switch (self) {
            self.text => true,
            else => false,
        };
    }

    pub fn render(self: El, buf: *std.ArrayList(u8)) !void {
        switch (self) {
            .base => |base| try base.render(buf),
            .text => |text| try buf.appendSlice(text),
        }
    }
};

// Helper type for element children
pub const Children = ?[]const El;

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

    // @TODO
    pub fn render(self: ARIAProps, buf: *std.ArrayList(u8)) !void {
        if (self.activedescendant) |ad| {
            try buf.appendSlice(" aria-activedescendent=\"");
            try buf.appendSlice(ad);
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
    checked: ?Str = null,
    disabled: ?Str = null,
    height: ?Str = null,
    href: ?Str = null,
    hx: ?HTMXProps = null,
    id: ?Str = null,
    lang: ?Str = null,
    rel: ?Str = null,
    selected: ?Str = null,
    src: ?Str = null,
    style: ?Str = null,
    title: ?Str = null,
    type: ?Str = null,
    value: ?Str = null,
    width: ?Str = null,

    // @TODO
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
        if (self.checked) |checked| {
            try buf.appendSlice(" checked=\"");
            try buf.appendSlice(checked);
            try buf.appendSlice("\"");
        }
        if (self.disabled) |disabled| {
            try buf.appendSlice(" disabled=\"");
            try buf.appendSlice(disabled);
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
        if (self.src) |src| {
            try buf.appendSlice(" src=\"");
            try buf.appendSlice(src);
            try buf.appendSlice("\"");
        }
        if (self.title) |title| {
            try buf.appendSlice(" title=\"");
            try buf.appendSlice(title);
            try buf.appendSlice("\"");
        }
        if (self.type) |t| {
            try buf.appendSlice(" type=\"");
            try buf.appendSlice(t);
            try buf.appendSlice("\"");
        }
    }
};

pub const BaseTag = struct {
    tag: Str,
    children: Children,
    props: ?Props = null,

    pub fn render(self: BaseTag, buf: *std.ArrayList(u8)) anyerror!void {
        try buf.appendSlice("<");
        try buf.appendSlice(self.tag);
        if (self.props) |props| {
            try props.render(buf);
        }
        try buf.appendSlice(">");

        if (self.children) |children| {
            for (children) |child| {
                try child.render(buf);
            }
        }

        try buf.appendSlice("</");
        try buf.appendSlice(self.tag);
        try buf.appendSlice(">");
    }
};

const TagFn = fn (comptime Children) type;

pub fn Text(content: Str) El {
    return El{ .text = @constCast(content) };
}

pub fn Element(comptime tag: Str) TagFn {
    const Closure = struct {
        fn tagFn(comptime children: Children) type {
            return struct {
                tag: Str = tag,
                children: Children = children,
            };
        }
    };
    return Closure.tagFn;
}

fn baseMake(base: BaseTag) El {
    return El{ .base = base };
}

fn baseElementConfig(comptime tag: Str, comptime props: ?Props, comptime children: Children) type {
    const el = Element(tag)(children){};
    const base = BaseTag{ .tag = el.tag, .children = el.children, .props = props };
    return struct {
        const Self = @This();
        base: BaseTag = base,
        pub fn make(self: Self) El {
            return baseMake(self.base);
        }
    };
}

// @TODO: add more elements

pub fn html(comptime props: ?Props, comptime children: Children) type {
    const el = Element("html")(children){};
    return struct {
        base: BaseTag = BaseTag{ .tag = el.tag, .children = el.children, .props = props },
    };
}

pub fn b(comptime props: ?Props, comptime children: Children) type {
    return baseElementConfig("b", props, children);
}

pub fn body(comptime props: ?Props, comptime children: Children) type {
    return baseElementConfig("body", props, children);
}

pub fn div(comptime props: ?Props, comptime children: Children) type {
    return baseElementConfig("div", props, children);
}

pub fn h1(comptime props: ?Props, comptime children: Children) type {
    return baseElementConfig("h1", props, children);
}

pub fn h2(comptime props: ?Props, comptime children: Children) type {
    return baseElementConfig("h2", props, children);
}

pub fn h3(comptime props: ?Props, comptime children: Children) type {
    return baseElementConfig("h3", props, children);
}

pub fn h4(comptime props: ?Props, comptime children: Children) type {
    return baseElementConfig("h4", props, children);
}

pub fn h5(comptime props: ?Props, comptime children: Children) type {
    return baseElementConfig("h5", props, children);
}

pub fn h6(comptime props: ?Props, comptime children: Children) type {
    return baseElementConfig("h6", props, children);
}

pub fn head(comptime props: ?Props, comptime children: Children) type {
    return baseElementConfig("head", props, children);
}

pub fn i(comptime props: ?Props, comptime children: Children) type {
    return baseElementConfig("i", props, children);
}

pub fn img(comptime props: ?Props, comptime children: Children) type {
    return baseElementConfig("img", props, children);
}

pub fn li(comptime props: ?Props, comptime children: Children) type {
    return baseElementConfig("li", props, children);
}

pub fn link(comptime props: ?Props, comptime children: Children) type {
    return baseElementConfig("link", props, children);
}

pub fn meta(comptime props: ?Props, comptime children: Children) type {
    return baseElementConfig("meta", props, children);
}

pub fn ol(comptime props: ?Props, comptime children: Children) type {
    return baseElementConfig("ol", props, children);
}

pub fn p(comptime props: ?Props, comptime children: Children) type {
    return baseElementConfig("p", props, children);
}

pub fn script(comptime props: ?Props, comptime children: Children) type {
    return baseElementConfig("script", props, children);
}

pub fn span(comptime props: ?Props, comptime children: Children) type {
    return baseElementConfig("span", props, children);
}

pub fn table(comptime props: ?Props, comptime children: Children) type {
    return baseElementConfig("table", props, children);
}

pub fn td(comptime props: ?Props, comptime children: Children) type {
    return baseElementConfig("td", props, children);
}

pub fn th(comptime props: ?Props, comptime children: Children) type {
    return baseElementConfig("th", props, children);
}

pub fn tr(comptime props: ?Props, comptime children: Children) type {
    return baseElementConfig("tr", props, children);
}

pub fn ul(comptime props: ?Props, comptime children: Children) type {
    return baseElementConfig("ul", props, children);
}

const header = (head(null, null){}).make();
// minimal example
pub const example = html(Props{
    .lang = "en-US",
    // children array must be passed as pointer
}, &[_]El{
    // props are first arg, children second
    // must pass null if element has no props/children
    // must also call make, which standardizes element structs
    header,
    (body(Props{
        .class = "body",
    }, &[_]El{
        (div(Props{
            .id = "app",
            .class = "test",
        }, &[_]El{
            Text("test content"),
        }){}).make(),
    }){}).make(),
}){};
