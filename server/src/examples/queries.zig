const std = @import("std");
const Server = @import("Server");

// GET /numbers?start=3&end=10 will return "[3,4,5,6,7,8,9,10]"

pub fn main() !void {
    var server = Server.init(std.heap.page_allocator);
    defer server.deinit();

    const handlers = struct {
        fn numbers(res: *Server.Response) !void {
            var start: ?u32 = null;
            var end: ?u32 = null;
            if(res.query("start")) |s| start = try std.fmt.parseUnsigned(u8, s, 10);
            if(res.query("end")) |e| end = try std.fmt.parseUnsigned(u8, e, 10);

            if(start != null and end != null and start.? <= end.?) {
                var nums = std.ArrayList(u32).init(std.heap.page_allocator);
                for(start.?..end.? + 1) |n| {
                    try nums.append(@intCast(n));
                }
                try res.sendJSON(.ok, nums.items);
            } else {
                try res.send(.ok, "[]");
            }
        }
    };

    try server.get("/numbers", &.{ handlers.numbers });

    std.debug.print("Listening on 0.0.0.0:8080\n", .{});
    try server.listen(.{0, 0, 0, 0}, 8080);
}