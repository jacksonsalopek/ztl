pub const Str = []const u8;
pub const El = union(enum) {
    base: BaseTag,
    text: []u8,

    fn isText(self: El) bool {
        return switch (self) {
            self.text => true,
            else => false,
        };
    }
};
pub const Children = ?[]const El;
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
};
pub const Props = struct {
    class: ?Str = null,
    hx: ?HTMXProps = null,
    id: ?Str = null,
    lang: ?Str = null,
};
pub const BaseTag = struct {
    tag: Str,
    children: Children,
    props: ?Props = null,
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

pub fn html(comptime props: ?Props, comptime children: Children) type {
    const el = Element("html")(children){};
    return struct {
        base: BaseTag = BaseTag{ .tag = el.tag, .children = el.children, .props = props },
    };
}

pub fn head(comptime props: ?Props, comptime children: Children) type {
    return baseElementConfig("head", props, children);
}

pub fn body(comptime props: ?Props, comptime children: Children) type {
    return baseElementConfig("body", props, children);
}

pub fn div(comptime props: ?Props, comptime children: Children) type {
    return baseElementConfig("div", props, children);
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
