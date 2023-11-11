const std = @import("std");
const Server = @import("Server");

// GET /greet/Bob will return "Hello Bob!"
// GET /greet/John will return "Go away John!"

pub fn main() !void {
    var server = Server.init(std.heap.page_allocator);
    defer server.deinit();

    const handlers = struct {
        fn greet(res: *Server.Response) !void {
            try res.sendFmt(.ok, "Hello {s}!", .{ res.param("name").? });
        }

        fn denyJohn(res: *Server.Response) !void {
            if(std.mem.eql(u8, res.param("name").?, "John")) {
                try res.send(.forbidden, "Go away John!");
                // When calling .send in a middleware function you must also either
                // call .done to stop executing additional functions or call .reset.
                // If you try calling .send multiple times without reseting the server
                // will crash
                res.done();
            }
        }
    };

    try server.get("/greet/:name", &.{ handlers.denyJohn, handlers.greet });

    std.debug.print("Listening on 0.0.0.0:8080\n", .{});
    try server.listen(.{0, 0, 0, 0}, 8080);
}