const std = @import("std");
const Server = @import("Server");

// POST /login with {"username": "John", "password": "1234"} will return "Logged in as John"

pub fn main() !void {
    var server = Server.init(std.heap.page_allocator);
    defer server.deinit();

    const handlers = struct {
        const LoginInfo = struct {
            username: []const u8,
            password: []const u8
        };

        fn login(res: *Server.Response) !void {
            var linfo = try res.readJSON(LoginInfo, std.heap.page_allocator, .{});
            defer linfo.deinit();

            if(std.mem.eql(u8, linfo.value.password, "1234")) {
                try res.sendFmt(.ok, "Logged in as {s}", .{ linfo.value.username });
            } else {
                try res.send(.forbidden, "Wrong password");
            }

        }
    };

    try server.post("/login", &.{ handlers.login });

    std.debug.print("Listening on 0.0.0.0:8080\n", .{});
    try server.listen(.{0, 0, 0, 0}, 8080);
}