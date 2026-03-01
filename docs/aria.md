# ARIA Support

ztl provides comprehensive ARIA support for accessible web applications via the `.aria` property.

## Accessible Button

```zig
try z.button(.{
    .props = .{
        .aria = .{
            .role = "button",
            .label = "Close dialog",
            .pressed = "false",
        },
    },
    .content = .{ .text = "×" },
})
```

## Expandable Section

```zig
try z.div(.{
    .props = .{
        .id = "accordion-header",
        .aria = .{
            .expanded = "false",
            .controls = "accordion-content",
        },
    },
    .content = .{ .text = "Click to expand" },
})
```

## Live Region

```zig
try z.div(.{
    .props = .{
        .aria = .{
            .live = "polite",
            .role = "status",
        },
    },
    .content = .{ .text = "Loading..." },
})
```

## Accessible Form

```zig
try z.form(.{ .children = &[_]El{
    try z.label(.{
        .props = .{
            .aria = .{ .labelledby = "username-label" },
        },
        .content = .{ .text = "Username" },
    }),
    try z.input(.{
        .props = .{
            .id = "username",
            .aria = .{
                .describedby = "username-help",
                .required = "true",
            },
        },
    }),
    try z.span(.{
        .props = .{ .id = "username-help" },
        .content = .{ .text = "Must be 3-20 characters" },
    }),
} })
```

## Available ARIA Properties

`activedescendant`, `checked`, `controls`, `describedby`, `disabled`, `expanded`, `hidden`, `label`, `labelledby`, `live`, `owns`, `pressed`, `role`, `selected`.
