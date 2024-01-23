# ztl - Zig Templating Language

Zig HTML templating with no dependencies.

## Core Features

1. HTML5-compatible
2. Accessible - `.aria` key available on Props
3. HTMX-compatible - `.hx` key available on Props
4. (Relatively) Easy to use.

## Using ztl

Section in progress. Please refer to the tests in `src/main.zig` for example usage.

```zig
const std = @import("std");
const z = @import("ztl");

// alias ztl types for ease-of-use
const El = z.El;
const Props = z.Props;
const Text = z.Text;

pub fn main() !void {
  // define markup
  const markup = z.html(Props{
    .lang = "en-US",
  }, &[_]El{
    z.body(null, &[_]El{
      z.p(Props{
        .class = "text",
      }, &[_]El{Text("Hello from ztl!")}),
    // must call el to convert BaseTag to El type.
    // this is necessary since text is not a tag.
    }).el(),
  });

  // create allocator for writing to buffer
  var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
  defer arena.deinit();
  const alloc = arena.allocator();
  
  // create the buffer
  var buf = std.ArrayList(u8).init(alloc);
  defer buf.deinit();
  
  // first param is buffer to print to, second is whether to print compact or not
  try markup.render(&buf, true);
  const renderedMarkup = buf.toOwnedSlice();
}
```

## Benchmarks

Section in progress.
