const std = @import("std");
const args = @import("args");

test "duplicate flag" {
    var parser = args.Parser.init(std.heap.page_allocator, "Test", "Test");
    try parser.addFlag("flag", "desc", null);
    var errored = false;
    parser.addFlag("flag", "desc", null) catch |err| {
        try std.testing.expect(err == error.DuplicateArgument);
        try std.testing.expectEqualStrings("flag", parser.err.?);
        errored =  true;
    };
    try std.testing.expect(errored);
}

test "duplicate option" {
    var parser = args.Parser.init(std.heap.page_allocator, "Test", "Test");
    try parser.addOption("opt", "desc", null, "", null);
    var errored = false;
    parser.addOption("opt", "desc", null, "", null) catch |err| {
        try std.testing.expect(err == error.DuplicateArgument);
        try std.testing.expectEqualStrings("opt", parser.err.?);
        errored = true;
    };
    try std.testing.expect(errored);
}

test "duplicate command" {
    var parser = args.Parser.init(std.heap.page_allocator, "Test", "Test");
    try parser.addCommand("cmd", "desc");
    var errored = false;
    parser.addCommand("cmd", "desc") catch |err| {
        try std.testing.expect(err == error.DuplicateArgument);
        try std.testing.expectEqualStrings("cmd", parser.err.?);
        errored = true;
    };
    try std.testing.expect(errored);
}

test "invalid argument" {
    var astr: [64:0]u8 = undefined;
    std.mem.copy(u8, &astr, "exe\x00 --arg\x00");
    var a: [2][:0]u8 = .{ astr[0..3:0], astr[5..10:0] };
    var parser = args.Parser.init(std.heap.page_allocator, "Test", "Test");
    var errored = false;
    _ = parser.parse(&a) catch |err| {
        try std.testing.expect(err == error.InvalidArgument);
        try std.testing.expectEqualStrings("arg", parser.err.?);
        errored = true;
    };
    try std.testing.expect(errored);
}

test "invalid value" {
    var astr: [64:0]u8 = undefined;
    std.mem.copy(u8, &astr, "exe\x00 --arg=maybe\x00");
    var a: [2][:0]u8 = .{ astr[0..3:0], astr[5..16:0] };
    var parser = args.Parser.init(std.heap.page_allocator, "Test", "Test");
    var allowed = std.ArrayList([]const u8).init(std.heap.page_allocator);
    try allowed.append("yes");
    try allowed.append("no");
    try parser.addOption("arg", "Test", null, "no", allowed);
    var errored = false;
    _ = parser.parse(&a) catch |err| {
        try std.testing.expect(err == error.InvalidValue);
        try std.testing.expectEqualStrings("arg", parser.err.?);
        errored = true;
    };
    try std.testing.expect(errored);
}

test "missing value" {
    var astr: [64:0]u8 = undefined;
    std.mem.copy(u8, &astr, "exe\x00 --arg\x00");
    var a: [2][:0]u8 = .{ astr[0..3:0], astr[5..10:0] };
    var parser = args.Parser.init(std.heap.page_allocator, "Test", "Test");
    try parser.addOption("arg", "Test", null, "", null);
    var errored = false;
    _ = parser.parse(&a) catch |err| {
        try std.testing.expect(err == error.MissingValue);
        try std.testing.expectEqualStrings("arg", parser.err.?);
        errored = true;
    };
    try std.testing.expect(errored);
}

test "parse" {
    var astr: [64:0]u8 = undefined;
    std.mem.copy(u8, &astr, "exe\x00 --op=test\x00 -f\x00 TEST\x00 -xyO=10\x00 --zflag\x00");
    var a: [6][:0]u8 = .{
        astr[0..3:0], astr[5..14:0], astr[16..18:0],
        astr[20..24:0], astr[26..33:0], astr[35..42:0]
    };
    var parser = args.Parser.init(std.heap.page_allocator, "Test", "Test");
    try parser.addOption("op", "Test", null, "", null);
    try parser.addOption("op2", "Test", 'O', "5", null);
    try parser.addOption("op3", "Test", null, null, null);
    try parser.addFlag("flag", "Test", 'f');
    try parser.addFlag("xflag", "Test", 'x');
    try parser.addFlag("yflag", "Test", 'y');
    try parser.addFlag("zflag", "Test", 'z');
    try parser.addFlag("no-flag", "Test", null);

    var results = try parser.parse(&a);
    try std.testing.expectEqualStrings("test", results.option.?.get("op").?);
    try std.testing.expectEqualStrings("10", results.option.?.get("op2").?);
    try std.testing.expect(results.option.?.get("op3") == null);
    try std.testing.expect(results.flag.?.get("flag").?);
    try std.testing.expect(results.flag.?.get("xflag").?);
    try std.testing.expect(results.flag.?.get("yflag").?);
    try std.testing.expect(results.flag.?.get("zflag").?);
    try std.testing.expectEqualStrings("TEST", results.positional.?.items[0]);
}

test "command" {
    var astr: [64:0]u8 = undefined;
    std.mem.copy(u8, &astr, "exe\x00 command\x00");
    var a: [2][:0]u8 = .{
        astr[0..3:0], astr[5..12:0]
    };

    var parser = args.Parser.init(std.heap.page_allocator, "Test", "Test");
    try parser.addCommand("command", "Test");

    var results = try parser.parse(&a);
    try std.testing.expectEqualStrings("command", results.command.?);
}

test "missing command" {
    var astr: [64:0]u8 = undefined;
    std.mem.copy(u8, &astr, "exe\x00 command\x00");
    var a: [2][:0]u8 = .{
        astr[0..3:0], astr[5..12:0]
    };

    var parser = args.Parser.init(std.heap.page_allocator, "Test", "Test");
    parser.command_required = true;
    try parser.addCommand("cmd", "Test");

    var errored = false;
    _ = parser.parse(&a) catch |err| {
        try std.testing.expect(err == error.InvalidArgument);
        errored = true;
    };
    try std.testing.expect(errored);
}
