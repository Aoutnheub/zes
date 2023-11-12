# Server

## Fields

```zig
allocator: std.mem.Allocator
```

```zig
notfound: HandlerFunc = Self.defaultNotFound
```

```zig
logger: ?HandlerFunc = Self.defaultLogger
```

## Functions

```zig
fn init(alloc: std.mem.Allocator) Self
```

```zig
fn deinit(self: *Self) void
```

```zig
fn get(self: *Self, path: []const u8, handler: []const HandlerFunc) !void
```

Calls `addHandler` with GET method

```zig
fn head(self: *Self, path: []const u8, handler: []const HandlerFunc) !void
```

Calls `addHandler` with HEAD method

```zig
fn post(self: *Self, path: []const u8, handler: []const HandlerFunc) !void
```

Calls `addHandler` with POST method

```zig
fn put(self: *Self, path: []const u8, handler: []const HandlerFunc) !void
```

Calls `addHandler` with PUT method

```zig
fn delete(self: *Self, path: []const u8, handler: []const HandlerFunc) !void
```

Calls `addHandler` with DELETE method

```zig
fn connect(self: *Self, path: []const u8, handler: []const HandlerFunc) !void
```

Calls `addHandler` with CONNECT method

```zig
fn options(self: *Self, path: []const u8, handler: []const HandlerFunc) !void
```

Calls `addHandler` with OPTIONS method

```zig
fn trace(self: *Self, path: []const u8, handler: []const HandlerFunc) !void
```

Calls `addHandler` with TRACE method

```zig
fn patch(self: *Self, path: []const u8, handler: []const HandlerFunc) !void
```

Calls `addHandler` with PATCH method

```zig
fn addHandler(
    self: *Self, method: std.http.Method, path: []const u8, funcs: []const HandlerFunc
) (std.mem.Allocator.Error || error { PathExists })!void
```

Add a list of handler functions for the specified method and path

- `method` : HTTP method
- `path` : handler path
- `funcs` : handler functions, will be called in order

```zig
fn listen(self: *Self, addr: [4]u8, port: u16) !void
```

Start the server

- `addr` IPv4 address
- `port` port

```zig
fn defaultNotFound(res: *Response) !void
```

Default function called when the path of a request doesn't exist

```zig
fn defaultLogger(res: *Response) !void
```

Default logging function