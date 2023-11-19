const std = @import("std");
const Server = @import("Server");

// GET /static.zig will return this file

pub fn main() !void {
    var server = Server.init(std.heap.page_allocator);
    defer server.deinit();

    try server.static("/", "src/examples/static.zig");

    std.debug.print("Listening on 0.0.0.0:8080\n", .{});
    try server.listen(.{0, 0, 0, 0}, 8080);
}