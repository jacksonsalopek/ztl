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

    pub fn render(self: El, buf: *std.ArrayList(u8), compact: bool) !void {
        switch (self) {
            .base => |base| try base.render(buf, compact),
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
    // @TODO: convert to bool
    checked: ?Str = null,
    // @TODO: convert to bool
    disabled: ?Str = null,
    // @TODO: convert to u16
    height: ?Str = null,
    href: ?Str = null,
    hx: ?HTMXProps = null,
    id: ?Str = null,
    lang: ?Str = null,
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

    pub fn el(self: BaseTag) El {
        return El{ .base = self };
    }
};

pub fn Text(content: Str) El {
    return El{ .text = @constCast(content) };
}

fn baseElementConfig(tag: Str, props: ?Props, children: Children) BaseTag {
    return BaseTag{ .tag = tag, .children = children, .props = props };
}

pub fn html(props: ?Props, children: Children) BaseTag {
    return baseElementConfig("html", props, children);
}

pub fn b(props: ?Props, children: Children) BaseTag {
    return baseElementConfig("b", props, children);
}

pub fn body(props: ?Props, children: Children) BaseTag {
    return baseElementConfig("body", props, children);
}

pub fn div(props: ?Props, children: Children) BaseTag {
    return baseElementConfig("div", props, children);
}

pub fn h1(props: ?Props, children: Children) BaseTag {
    return baseElementConfig("h1", props, children);
}

pub fn h2(props: ?Props, children: Children) BaseTag {
    return baseElementConfig("h2", props, children);
}

pub fn h3(props: ?Props, children: Children) BaseTag {
    return baseElementConfig("h3", props, children);
}

pub fn h4(props: ?Props, children: Children) BaseTag {
    return baseElementConfig("h4", props, children);
}

pub fn h5(props: ?Props, children: Children) BaseTag {
    return baseElementConfig("h5", props, children);
}

pub fn h6(props: ?Props, children: Children) BaseTag {
    return baseElementConfig("h6", props, children);
}

pub fn head(props: ?Props, children: Children) BaseTag {
    return baseElementConfig("head", props, children);
}

pub fn i(props: ?Props, children: Children) BaseTag {
    return baseElementConfig("i", props, children);
}

pub fn img(props: ?Props, children: Children) BaseTag {
    return baseElementConfig("img", props, children);
}

pub fn li(props: ?Props, children: Children) BaseTag {
    return baseElementConfig("li", props, children);
}

pub fn link(props: ?Props, children: Children) BaseTag {
    return baseElementConfig("link", props, children);
}

pub fn meta(props: ?Props, children: Children) BaseTag {
    return baseElementConfig("meta", props, children);
}

pub fn ol(props: ?Props, children: Children) BaseTag {
    return baseElementConfig("ol", props, children);
}

pub fn p(props: ?Props, children: Children) BaseTag {
    return baseElementConfig("p", props, children);
}

pub fn script(props: ?Props, children: Children) BaseTag {
    return baseElementConfig("script", props, children);
}

pub fn span(props: ?Props, children: Children) BaseTag {
    return baseElementConfig("span", props, children);
}

pub fn table(props: ?Props, children: Children) BaseTag {
    return baseElementConfig("table", props, children);
}

pub fn td(props: ?Props, children: Children) BaseTag {
    return baseElementConfig("td", props, children);
}

pub fn th(props: ?Props, children: Children) BaseTag {
    return baseElementConfig("th", props, children);
}

pub fn title(props: ?Props, children: Children) BaseTag {
    return baseElementConfig("title", props, children);
}

pub fn tr(props: ?Props, children: Children) BaseTag {
    return baseElementConfig("tr", props, children);
}

pub fn ul(props: ?Props, children: Children) BaseTag {
    return baseElementConfig("ul", props, children);
}

// minimal example
const header = head(null, &[_]El{
    title(null, &[_]El{
        Text("Test page"),
    }).el(),
}).el();
pub const example = html(Props{
    .lang = "en-US",
    // children array must be passed as pointer
}, &[_]El{
    // props are first arg, children second
    // must pass null if element has no props/children
    // must also call make, which standardizes element structs
    header,
    body(Props{
        .class = "body",
    }, &[_]El{
        div(Props{
            .id = "app",
            .class = "test",
        }, &[_]El{
            Text("test content"),
        }).el(),
    }).el(),
});
