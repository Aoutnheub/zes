const std = @import("std");
const Server = @import("Server");

// GET / will redirect to /greet

pub fn main() !void {
    var server = Server.init(std.heap.page_allocator);
    defer server.deinit();

    const handlers = struct {
        fn greet(res: *Server.Response) !void {
            try res.send(.ok, "Hello!");
        }

        fn redirect(res: *Server.Response) !void {
            try res.redirect(.temporary_redirect, "/greet");
        }
    };

    try server.get("/greet", &.{ handlers.greet });
    try server.get("/", &.{ handlers.redirect });

    std.debug.print("Listening on 0.0.0.0:8080\n", .{});
    try server.listen(.{0, 0, 0, 0}, 8080);
}