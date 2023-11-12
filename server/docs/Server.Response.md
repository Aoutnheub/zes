# Response

Response passed to every handler function

## Fields

```zig
allocator: std.mem.Allocator
```

```zig
res: *std.http.Server.Response
```

```zig
params: std.StringHashMap([]const u8)
```

```zig
queries: std.StringHashMap([]const u8)
```

```zig
cookies: std.StringHashMap([]const u8)
```

```zig
max_body_size: usize = 8_000_000
```

## Functions

```zig
fn init(alloc: std.mem.Allocator, res: *std.http.Server.Response) Response
```

```zig
fn deinit(self: *Response) void
```

```zig
fn wait(self: *Response) std.http.Server.Response.WaitError!void
```

Wait for the client to send a complete request head.

```zig
fn do(self: *Response) !void
```

Send the response headers

```zig
fn write(self: *Response, bytes: []const u8) std.http.Server.Response.WriteError!usize
```

Write bytes to the server. The transfer_encoding request header determines how data will be sent

```zig
fn finish(self: *Response) std.http.Server.Response.FinishError!void
```

Finish the body of the request. This notifies the server that you have no more data to send

```zig
fn reset(self: *Response) std.http.Server.Response.ResetState
```

Reset the underlying response to its initial state. This must be called before handling a second request on the same connection

```zig
fn param(self: *Response, name: []const u8) ?[]const u8
```

Get parameter by name. Equivalent to `.params.get("<name>")`

- `name` : parameter name

```zig
fn query(self: *Response, name: []const u8) ?[]const u8
```

Get query by name. Equivalent to `.queries.get("<name>")`

- `name` : query name

```zig
fn cookie(self: *Response, name: []const u8) ?[]const u8
```

Get cookie by name. Equivalent to `.cookies.get("<name>")`

- `name` : cookie name

```zig
fn target(self: *Response) []const u8
```

Get the target path

```zig
fn method(self: *Response) std.http.Method
```

Get the HTTP method

```zig
fn send(self: *Response, status: std.http.Status, bytes: []const u8) !void
```

Send the status and bytes to the user. This function starts and finishes the request. To send a formatted message or JSON see `sendFmt` and `sendJSON`

```zig
fn sendFmt(self: *Response, status: std.http.Status, comptime fmt: []const u8, args: anytype) !void
```

Send the status and a formatted message to the user. This function starts and finishes the request. If you want to just send some bytes use `send`

```zig
fn sendJSON(self: *Response, status: std.http.Status, obj: anytype) !void
```

Send the status and a JSON object to the user. This function starts and finishes the request. If you want to just send some bytes use `send`

```zig
fn redirect(self: *Response, status: std.http.Status, link: []const u8) !void
```

Redirect request

- `status` : only codes 300-399
- `link` : new path

```zig
fn read(self: *Response, buf: []u8) ![]u8
```

Read the body of the request

- `buf` : buffer where data will be written

```zig
fn readAll(self: *Response, buf: []u8) ![]u8
```

Read the body of the request

- `buf` : buffer where data will be written

```zig
fn readAllAlloc(self: *Response, alloc: std.mem.Allocator) ![]u8
```

Read the body of the request. `max_body_size` sets the maximum amount of bytes to read

- `alloc` : allocator for the buffer

```zig
fn readJSON(self: *Response, comptime T: type, alloc: std.mem.Allocator, opts: std.json.ParseOptions) !std.json.Parsed(T)
```

Read the body as JSON

- `T` : struct type
- `alloc` : allocator
- `opts` : json options

```zig
fn done(self: *Response) void
```

Don't call any more handler functions
