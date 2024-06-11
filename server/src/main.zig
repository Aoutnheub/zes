/// MIT License

/// Copyright (c) 2023 Aoutnheub

/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:

/// The above copyright notice and this permission notice shall be included in all
/// copies or substantial portions of the Software.

/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
/// SOFTWARE.

/// Tested on Zig version: 0.11.0

const std = @import("std");

const Self = @This();

/// Path for handlers
/// ':' before a path section means that the section has a required variable value
///     Ex: '/greet/:name' will match '/greet/john' and '/greet/jane'
/// '*' before a path section means that the section has an optional variable value
///     Ex: '/greet/*name' will match '/greet' and '/greet/john'
pub const Path = struct {
    pub const Part = struct {
        pub const Type = enum { Static, Required, Optional };

        type: Type = .Static,
        value: ?[]u8 = null
    };

    allocator: std.mem.Allocator,
    parts: std.ArrayList(Part),

    pub fn init(alloc: std.mem.Allocator, path: []const u8) !Path {
        var s = Path{
            .allocator = alloc,
            .parts = std.ArrayList(Part).init(alloc)
        };

        var iter = std.mem.tokenizeScalar(u8, path, '/');
        while(iter.next()) |part| {
            var p: Part = undefined;
            switch(part[0]) {
                ':' => {
                    p = Part{
                        .type = .Required,
                        .value = try alloc.alloc(u8, part.len - 1),
                    };
                    @memcpy(p.value.?, part[1..]);
                },
                '*' => {
                    p = Part{
                        .type = .Optional,
                        .value = try alloc.alloc(u8, part.len - 1),
                    };
                    @memcpy(p.value.?, part[1..]);
                },
                else => {
                    p = Part{
                        .value = try alloc.alloc(u8, part.len),
                    };
                    @memcpy(p.value.?, part);
                }
            }
            try s.parts.append(p);
        }

        return s;
    }

    pub fn deinit(self: *Path) void {
        for(self.parts.items) |part| {
            if(part.value) |v| self.allocator.free(v);
        }
        self.parts.deinit();
    }

    /// Check if path matches the defined schema
    /// To compare with another Path struct use `eql`
    /// @param path path to compare
    pub fn match(self: *Path, path: []const u8) bool {
        var p: []const u8 = path;
        if(std.mem.indexOfScalar(u8, path, '?')) |i| p = path[0..i];

        var iter = std.mem.tokenizeScalar(u8, p, '/');
        var offset: usize = 0;
        while(iter.next()) |part| : (offset += 1) {
            if(offset >= self.parts.items.len) { return false; }
            if(self.parts.items[offset].type == .Static)
                if(!std.mem.eql(u8, self.parts.items[offset].value.?, part)) return false;
        }

        if(offset < self.parts.items.len and self.parts.items[offset].type != .Optional) {
            return false;
        }

        return true;
    }

    /// Check if two path schemas are the same
    /// To compare with a string path use `match`
    /// !IMPORTANT! '/greet/:name' and '/greet/:user' are the same because they will both match
    /// the same paths
    ///     Ex: Both will match the path '/greet/john'
    /// @param path path to compare
    pub fn eql(self: *Path, path: *Path) bool {
        if(self.parts.items.len != path.parts.items.len) return false;
        for(self.parts.items, 0..) |part, i| {
            if(part.type != path.parts.items[i].type) return false;
            if(part.type == .Static) {
                if(!std.mem.eql(u8, part.value.?, path.parts.items[i].value.?)) return false;
            }
        }

        return true;
    }
};

/// Response passed to every handler function
pub const Response = struct {
    allocator: std.mem.Allocator,
    res: *std.http.Server.Response,
    params: std.StringHashMap([]const u8),
    queries: std.StringHashMap([]const u8),
    cookies: std.StringHashMap([]const u8),
    max_body_size: usize = 8_000_000,
    _done: bool = false,

    pub fn init(alloc: std.mem.Allocator, res: *std.http.Server.Response) Response {
        return Response{
            .allocator = alloc,
            .res = res,
            .params = std.StringHashMap([]const u8).init(alloc),
            .queries = std.StringHashMap([]const u8).init(alloc),
            .cookies = std.StringHashMap([]const u8).init(alloc)
        };
    }

    pub fn deinit(self: *Response) void {
        self.res.deinit();
        self.params.deinit();
        self.queries.deinit();
        self.cookies.deinit();
    }

    /// Wait for the client to send a complete request head
    pub fn wait(self: *Response) std.http.Server.Response.WaitError!void {
        return self.res.wait();
    }

    /// Send the response headers
    pub fn do(self: *Response) !void {
        return self.res.do();
    }

    /// Write bytes to the server. The transfer_encoding request header determines how data will be sent
    pub fn write(self: *Response, bytes: []const u8) std.http.Server.Response.WriteError!usize {
        return self.res.write(bytes);
    }

    /// Finish the body of the request. This notifies the server that you have no more data to send
    pub fn finish(self: *Response) std.http.Server.Response.FinishError!void {
        return self.res.finish();
    }

    /// Reset the underlying response to its initial state. This must be called before
    /// handling a second request on the same connection
    pub fn reset(self: *Response) std.http.Server.Response.ResetState {
        return self.res.reset();
    }

    /// Get parameter by name
    /// Equivalent to .params.get("<name>")
    /// @param name parameter name
    pub fn param(self: *Response, name: []const u8) ?[]const u8 {
        return self.params.get(name);
    }

    /// Get query by name
    /// Equivalent to .queries.get("<name>")
    /// @param name query name
    pub fn query(self: *Response, name: []const u8) ?[]const u8 {
        return self.queries.get(name);
    }

    /// Get cookie by name
    /// Equivalent to .cookies.get("<name>")
    /// @param name cookie name
    pub fn cookie(self: *Response, name: []const u8) ?[]const u8 {
        return self.cookies.get(name);
    }

    /// Get the target path
    pub fn target(self: *Response) []const u8 {
        return self.res.request.target;
    }

    /// Get the HTTP method
    pub fn method(self: *Response) std.http.Method {
        return self.res.request.method;
    }

    /// Send the status and bytes to the user
    /// This function starts and finishes the request
    /// To send a formatted message or JSON see `sendFmt` and `sendJSON`
    pub fn send(self: *Response, status: std.http.Status, bytes: []const u8) !void {
        self.res.status = status;
        self.res.transfer_encoding = std.http.Server.ResponseTransfer{ .content_length = bytes.len };
        try self.do();
        _ = try self.write(bytes);
        try self.finish();
    }

    /// Send the status and a formatted message to the user
    /// This function starts and finishes the request
    /// If you want to just send some bytes use `send`
    pub fn sendFmt(self: *Response, status: std.http.Status, comptime fmt: []const u8, args: anytype) !void {
        const bytes = try std.fmt.allocPrint(self.allocator, fmt, args);
        defer self.allocator.free(bytes);
        try self.send(status, bytes);
    }

    /// Send the status and a JSON object to the user
    /// This function starts and finishes the request
    /// If you want to just send some bytes use `send`
    pub fn sendJSON(self: *Response, status: std.http.Status, obj: anytype) !void {
        const bytes = try std.json.stringifyAlloc(self.allocator, obj, .{});
        defer self.allocator.free(bytes);
        try self.send(status, bytes);
    }

    /// Redirect request
    /// @param status only codes 300-399
    /// @param link new path
    pub fn redirect(self: *Response, status: std.http.Status, link: []const u8) !void {
        self.res.status = status;
        if(!self.res.headers.contains("Location")) try self.res.headers.append("Location", link);
        try self.do();
        try self.finish();
    }

    /// Read the body of the request
    /// @param buf buffer where data will be written
    pub fn read(self: *Response, buf: []u8) ![]u8 {
        const size = try self.res.read(buf);

        return buf[0..size];
    }

    /// Read the body of the request
    /// @param buf buffer where data will be written
    pub fn readAll(self: *Response, buf: []u8) ![]u8 {
        const size = try self.res.readAll(buf);

        return buf[0..size];
    }

    /// Read the body of the request
    /// `max_body_size` sets the maximum amount of bytes to read
    /// @param alloc allocator for the buffer
    pub fn readAllAlloc(self: *Response, alloc: std.mem.Allocator) ![]u8 {
        return self.res.reader().readAllAlloc(alloc, self.max_body_size);
    }

    /// Read the body as JSON
    /// @param T struct type
    /// @param alloc allocator
    /// @param opts json options
    pub fn readJSON(self: *Response, comptime T: type, alloc: std.mem.Allocator, opts: std.json.ParseOptions) !std.json.Parsed(T) {
        var reader = std.json.reader(alloc, self.res.reader());
        defer reader.deinit();

        return std.json.parseFromTokenSource(T, alloc, &reader, opts);
    }

    /// Don't call any more handler functions
    pub fn done(self: *Response) void {
        self._done = true;
    }
};

pub const HandlerFunc = *const fn(*Response) anyerror!void;
const Handler = struct {
    path: Path,
    method: std.http.Method,
    funcs: std.ArrayList(HandlerFunc),

    pub fn deinit(self: *Handler) void {
        self.funcs.deinit();
        self.path.deinit();
    }
};

allocator: std.mem.Allocator,
notfound: HandlerFunc = Self.defaultNotFound,
logger: ?HandlerFunc = Self.defaultLogger,
_server: std.http.Server,
_handlers: std.ArrayList(Handler),

pub fn init(alloc: std.mem.Allocator) Self {
    const s = Self{
        .allocator = alloc,
        ._server = std.http.Server.init(alloc, .{}),
        ._handlers = std.ArrayList(Handler).init(alloc)
    };

    return s;
}

pub fn deinit(self: *Self) void {
    self._server.deinit();
    for(self._handlers.items) |*h| h.deinit();
    self._handlers.deinit();
}

/// Calls `addHandler` with GET method
pub fn get(self: *Self, path: []const u8, handler: []const HandlerFunc) !void {
    try self.addHandler(.GET, path, handler);
}

/// Calls `addHandler` with HEAD method
pub fn head(self: *Self, path: []const u8, handler: []const HandlerFunc) !void {
    try self.addHandler(.HEAD, path, handler);
}

/// Calls `addHandler` with POST method
pub fn post(self: *Self, path: []const u8, handler: []const HandlerFunc) !void {
    try self.addHandler(.POST, path, handler);
}

/// Calls `addHandler` with PUT method
pub fn put(self: *Self, path: []const u8, handler: []const HandlerFunc) !void {
    try self.addHandler(.PUT, path, handler);
}

/// Calls `addHandler` with DELETE method
pub fn delete(self: *Self, path: []const u8, handler: []const HandlerFunc) !void {
    try self.addHandler(.DELETE, path, handler);
}

/// Calls `addHandler` with CONNECT method
pub fn connect(self: *Self, path: []const u8, handler: []const HandlerFunc) !void {
    try self.addHandler(.CONNECT, path, handler);
}

/// Calls `addHandler` with OPTIONS method
pub fn options(self: *Self, path: []const u8, handler: []const HandlerFunc) !void {
    try self.addHandler(.OPTIONS, path, handler);
}

/// Calls `addHandler` with TRACE method
pub fn trace(self: *Self, path: []const u8, handler: []const HandlerFunc) !void {
    try self.addHandler(.TRACE, path, handler);
}

/// Calls `addHandler` with PATCH method
pub fn patch(self: *Self, path: []const u8, handler: []const HandlerFunc) !void {
    try self.addHandler(.PATCH, path, handler);
}

/// Add a list of handler functions for the specified method and path
/// @param method HTTP method
/// @param path handler path
/// @param funcs handler functions, will be called in order
/// @return error if path exists
pub fn addHandler(
    self: *Self, method: std.http.Method, path: []const u8, funcs: []const HandlerFunc
) (std.mem.Allocator.Error || error { PathExists })!void {
    var handler_funcs = std.ArrayList(HandlerFunc).init(self.allocator);
    for(funcs) |f| try handler_funcs.append(f);
    var h = Handler{
        .method = method,
        .path = try Path.init(self.allocator, path),
        .funcs = handler_funcs
    };
    for(self._handlers.items) |*hd| {
        if(method == hd.method and h.path.eql(&hd.path)) return error.PathExists;
    }
    try self._handlers.append(h);
}

/// Server a static file
/// @param path root URL path
/// @param file file path
pub fn static(self: *Self, comptime path: []const u8, comptime file: []const u8) !void {
    const func = struct {
        fn serverFile(res: *Response) !void {
            var f = try std.fs.cwd().openFile(file, .{});
            defer f.close();
            const content = try f.readToEndAlloc(std.heap.page_allocator, 8_000_000);
            defer std.heap.page_allocator.free(content);
            try res.send(.ok, content);
        }
    };
    comptime var file_name: []const u8 = undefined;
    comptime {
        if(std.mem.lastIndexOfScalar(u8, file, '/')) |idx| {
            file_name = file[idx + 1..];
        } else {
            file_name = file;
        }
    }
    try self.get(
        path ++ (if(path[path.len - 1] == '/' or file_name[file_name.len - 1] == '/') "" else "/") ++ file_name,
        &.{ func.serverFile }
    );
}

/// Start the server
/// @param addr IPv4 address
/// @param port port
pub fn listen(self: *Self, addr: [4]u8, port: u16) !void {
    try self._server.listen(std.net.Address.initIp4(addr, port));

    while(true) {
        const res = try self._server.accept(.{ .allocator = self.allocator });
        var thread = try std.Thread.spawn(.{}, newRequest, .{ self, res });
        thread.detach();
    }
}

/// Default function called when the path of a request doesn't exist
pub fn defaultNotFound(res: *Response) !void {
    try res.send(.not_found, "Not found");
}

/// Default logging function
pub fn defaultLogger(res: *Response) !void {
    var method: []const u8 = undefined;
    var method_color: []const u8 = undefined;
    switch(res.method()) {
        .GET => {
            method = "GET";
            method_color = "\x1b[42m";
        },
        .HEAD => {
            method = "HEAD";
            method_color = "\x1b[45m";
        },
        .POST => {
            method = "POST";
            method_color = "\x1b[45m";
        },
        .PUT => {
            method = "PUT";
            method_color = "\x1b[45m";
        },
        .DELETE => {
            method = "DELETE";
            method_color = "\x1b[41m";
        },
        .CONNECT => {
            method = "CONNECT";
            method_color = "\x1b[42m";
        },
        .OPTIONS => {
            method = "OPTIONS";
            method_color = "\x1b[44m";
        },
        .TRACE => {
            method = "TRACE";
            method_color = "\x1b[44m";
        },
        .PATCH => {
            method = "PATCH";
            method_color = "\x1b[43m";
        }
    }

    var status: [3]u8 = undefined;
    _ = try std.fmt.bufPrint(&status, "{}", .{ @intFromEnum(res.res.status) });
    var status_color: []const u8 = undefined;
    switch(@intFromEnum(res.res.status)) {
        100...199 => status_color = "\x1b[44m",
        200...299 => status_color = "\x1b[42m",
        300...399 => status_color = "\x1b[43m",
        400...499 => status_color = "\x1b[41m",
        500...599 => status_color = "\x1b[41m",
        else => unreachable
    }

    const reset_color = "\x1b[0m";
    const bold = "\x1b[1m";
    try std.io.getStdOut().writer().print(
        "{s}{s} {s} " ++ reset_color ++ " -> {s}{s} {s} " ++ reset_color ++ " {s}\n",
        .{ bold, status_color, status, bold, method_color, method, res.target() }
    );
}

/// Finds the handlers that match the path and calls them
fn newRequest(self: *Self, res_: std.http.Server.Response) !void {
    var res = Response.init(self.allocator, @constCast(&res_));
    defer res.deinit();
    try res.wait();

    var found = false;
    for(self._handlers.items) |*handler| {
        if(res.method() == handler.method and handler.path.match(res.target())) {
            // Gather parameters
            var target: []const u8 = res.target();
            if(std.mem.indexOfScalar(u8, target, '?')) |i| target = target[0..i];
            var target_parts = std.mem.tokenizeScalar(u8, target, '/');
            {
                var i: usize = 0;
                while(target_parts.next()) |p| : (i += 1) {
                    switch(handler.path.parts.items[i].type) {
                        .Required, .Optional => {
                            try res.params.put(handler.path.parts.items[i].value.?, p);
                        },
                        .Static => {}
                    }
                }
            }

            // Gather queries
            if(std.mem.indexOfScalar(u8, res.target(), '?')) |i| {
                var kvs = std.mem.tokenizeScalar(u8, res.target()[i + 1..], '&');
                while(kvs.next()) |kv| {
                    if(std.mem.indexOfScalar(u8, kv, '=')) |eql| {
                        try res.queries.put(kv[0..eql], kv[eql + 1..]);
                    }

                }
            }

            // Gather cookies
            if(res.res.request.headers.firstIndexOf("Cookie")) |cookie_idx| {
                const cookies = res.res.request.headers.list.items[cookie_idx];
                var iter = std.mem.tokenizeScalar(u8, cookies.value, ';');
                while(iter.next()) |cookie| {
                    if(std.mem.indexOfScalar(u8, cookie, '=')) |eql_idx| {
                        try res.cookies.put(cookie[0..eql_idx], cookie[eql_idx + 1..]);
                    }
                }
            }

            for(handler.funcs.items) |f| if(!res._done) try f(&res);
            found = true;
            break;
        }
    }
    if(!found) try self.notfound(&res);
    if(self.logger) |log| try log(&res);
}
