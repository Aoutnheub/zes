const std = @import("std");
const Server = @import("Server");

// GET / with cookie "user=John" will return "Hello John!"

pub fn main() !void {
    var server = Server.init(std.heap.page_allocator);
    defer server.deinit();

    const handlers = struct {
        fn greet(res: *Server.Response) !void {
            if(res.cookie("user")) |user| {
                try res.sendFmt(.ok, "Hello {s}!", .{ user });
            }
        }
    };

    try server.get("/", &.{ handlers.greet });

    std.debug.print("Listening on 0.0.0.0:8080\n", .{});
    try server.listen(.{0, 0, 0, 0}, 8080);
}