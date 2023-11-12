# Server.Path

Path for handlers

':' before a path section means that the section has a required variable value

Ex: '/greet/:name' will match '/greet/john' and '/greet/jane'

'*' before a path section means that the section has an optional variable value

Ex: '/greet/*name' will match '/greet' and '/greet/john'

## Fields

```zig
allocator: std.mem.Allocator
```

```zig
parts: std.ArrayList(Part)
```

## Functions

```zig
fn init(alloc: std.mem.Allocator, path: []const u8) !Path
```

```zig
fn deinit(self: *Path) void
```

```zig
fn match(self: *Path, path: []const u8) bool
```

Check if path matches the defined schema. To compare with another Path struct use `eql`

- `path` : path to compare

```zig
fn eql(self: *Path, path: *Path) bool
```

Check if two path schemas are the same. To compare with a string path use `match`

:exclamation: IMPORTANT :exclamation: '/greet/:name' and '/greet/:user' are the same because they will both match the same paths. Ex: Both will match the path '/greet/john'

- `path` : path to compare