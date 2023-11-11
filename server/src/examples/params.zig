const std = @import("std");
const Server = @import("Server");

// GET /greet will return "Hello!"
// GET /greet/John will return "Hello John!"

// GET /compliment/John will return "Nice face John!"
// GET /compliment will return "Not found"

pub fn main() !void {
    var server = Server.init(std.heap.page_allocator);
    defer server.deinit();

    const handlers = struct {
        fn greet(res: *Server.Response) !void {
            if(res.param("name")) |name| {
                try res.sendFmt(.ok, "Hello {s}!", .{ name });
            } else try res.send(.ok, "Hello!");
        }

        fn compliment(res: *Server.Response) !void {
            try res.sendFmt(.ok, "Nice face {s}!", .{ res.param("name").? });
        }
    };

    try server.get("/greet/*name", &.{ handlers.greet });
    try server.get("/compliment/:name", &.{ handlers.compliment });

    std.debug.print("Listening on 0.0.0.0:8080\n", .{});
    try server.listen(.{0, 0, 0, 0}, 8080);
}