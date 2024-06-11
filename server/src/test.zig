const std = @import("std");
const Server = @import("./main.zig");

// Test Path

test "Parse '/'" {
    var path = try Server.Path.init(std.heap.page_allocator, "/");
    defer path.deinit();

    try std.testing.expect(path.parts.items.len == 0);
}

test "Parse '/test'" {
    var path = try Server.Path.init(std.heap.page_allocator, "/test");
    defer path.deinit();

    try std.testing.expect(path.parts.items.len == 1);
    try std.testing.expect(path.parts.items[0].type == .Static);
    try std.testing.expectEqualStrings("test", path.parts.items[0].value.?);
}

test "Match for '/test'" {
    var path = try Server.Path.init(std.heap.page_allocator, "/test");
    defer path.deinit();

    try std.testing.expect(path.matches("/test"));
    try std.testing.expect(path.matches("/test?q=v"));
    try std.testing.expect(path.matches("/test/"));
    try std.testing.expect(path.matches("/test/?q=v"));
    try std.testing.expect(path.matches("/test/hello") == false);
    try std.testing.expect(path.matches("/test/hello?q=v") == false);
}

test "Parse '/test/:required'" {
    var path = try Server.Path.init(std.heap.page_allocator, "/test/:required");
    defer path.deinit();

    try std.testing.expect(path.parts.items.len == 2);
    try std.testing.expect(path.parts.items[0].type == .Static);
    try std.testing.expect(path.parts.items[1].type == .Required);
    try std.testing.expectEqualStrings("test", path.parts.items[0].value.?);
    try std.testing.expectEqualStrings("required", path.parts.items[1].value.?);
}

test "Match for '/test/:required'" {
    var path = try Server.Path.init(std.heap.page_allocator, "/test/:required");
    defer path.deinit();

    try std.testing.expect(path.matches("/test/") == false);
    try std.testing.expect(path.matches("/test?q=v") == false);
    try std.testing.expect(path.matches("/test/1"));
    try std.testing.expect(path.matches("/test/1?q=v"));
    try std.testing.expect(path.matches("/test/1/2") == false);
    try std.testing.expect(path.matches("/test/1/2?q=v") == false);
}

test "Parse '/test/*optional'" {
    var path = try Server.Path.init(std.heap.page_allocator, "/test/*optional");
    defer path.deinit();

    try std.testing.expect(path.parts.items.len == 2);
    try std.testing.expect(path.parts.items[0].type == .Static);
    try std.testing.expect(path.parts.items[1].type == .Optional);
    try std.testing.expectEqualStrings("test", path.parts.items[0].value.?);
    try std.testing.expectEqualStrings("optional", path.parts.items[1].value.?);
}

test "Match for '/test/*optional'" {
    var path = try Server.Path.init(std.heap.page_allocator, "/test/*optional");
    defer path.deinit();

    try std.testing.expect(path.matches("/test/"));
    try std.testing.expect(path.matches("/test?q=v"));
    try std.testing.expect(path.matches("/test/1"));
    try std.testing.expect(path.matches("/test/1?q=v"));
    try std.testing.expect(path.matches("/test/1/2") == false);
    try std.testing.expect(path.matches("/test/1/2?q=v") == false);
}

test "Parse '/test/:required/*optional'" {
    var path = try Server.Path.init(std.heap.page_allocator, "/test/:required/*optional");
    defer path.deinit();

    try std.testing.expect(path.parts.items.len == 3);
    try std.testing.expect(path.parts.items[0].type == .Static);
    try std.testing.expect(path.parts.items[1].type == .Required);
    try std.testing.expect(path.parts.items[2].type == .Optional);
    try std.testing.expectEqualStrings("test", path.parts.items[0].value.?);
    try std.testing.expectEqualStrings("required", path.parts.items[1].value.?);
    try std.testing.expectEqualStrings("optional", path.parts.items[2].value.?);
}

test "Match for '/test/:required/*optional'" {
    var path = try Server.Path.init(std.heap.page_allocator, "/test/:required/*optional");
    defer path.deinit();

    try std.testing.expect(path.matches("/test/") == false);
    try std.testing.expect(path.matches("/test?q=v") == false);
    try std.testing.expect(path.matches("/test/1"));
    try std.testing.expect(path.matches("/test/1?q=v"));
    try std.testing.expect(path.matches("/test/1/2"));
    try std.testing.expect(path.matches("/test/1/2?q=v"));
    try std.testing.expect(path.matches("/test/1/2/3") == false);
    try std.testing.expect(path.matches("/test/1/2/3?q=v") == false);
}

test "Test equality between '/test' and '/tests'" {
    var path0 = try Server.Path.init(std.heap.page_allocator, "/test");
    defer path0.deinit();
    var path1 = try Server.Path.init(std.heap.page_allocator, "/tests");
    defer path1.deinit();

    try std.testing.expect(path0.eql(path1) == false);
}

test "Test equality between '/test' and '/test/one'" {
    var path0 = try Server.Path.init(std.heap.page_allocator, "/test");
    defer path0.deinit();
    var path1 = try Server.Path.init(std.heap.page_allocator, "/test/one");
    defer path1.deinit();

    try std.testing.expect(path0.eql(path1) == false);
}

test "Test equality between '/test/:required' and '/test/:req'" {
    var path0 = try Server.Path.init(std.heap.page_allocator, "/test/:required");
    defer path0.deinit();
    var path1 = try Server.Path.init(std.heap.page_allocator, "/test/:req");
    defer path1.deinit();

    try std.testing.expect(path0.eql(path1));
}

test "Test equality between '/test/*optional' and '/test/*opt'" {
    var path0 = try Server.Path.init(std.heap.page_allocator, "/test/*optional");
    defer path0.deinit();
    var path1 = try Server.Path.init(std.heap.page_allocator, "/test/*opt");
    defer path1.deinit();

    try std.testing.expect(path0.eql(path1));
}

test "Test equality between '/test/:required' and '/test/*optional'" {
    var path0 = try Server.Path.init(std.heap.page_allocator, "/test/:required");
    defer path0.deinit();
    var path1 = try Server.Path.init(std.heap.page_allocator, "/test/*optional");
    defer path1.deinit();

    try std.testing.expect(path0.eql(path1) == false);
}
