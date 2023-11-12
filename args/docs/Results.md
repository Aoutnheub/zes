# Results

## Fields

```zig
allocator: std.mem.Allocator
```

```zig
flag: ?std.hash_map.StringHashMap(bool) = null
```

Stores flag values after parsing

```zig
option: ?std.hash_map.StringHashMap([]const u8) = null
```

Stores option values after parsing

```zig
positional: ?std.ArrayList([]const u8) = null
```

Stores positional arguments after parsing

```zig
command: ?[]u8 = null
```

Stores the command after parsing


## Functions

```zig
fn deinit(self: *Results) void
```