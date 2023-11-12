## Description

Command line argument parser.

## Example

```zig
const std = @import("std");
const args = @import("args");

pub fn main() !void {
    var parser = args.Parser.init(std.heap.page_allocator, "hi", "Say hi");
    defer parser.deinit();

    try parser.addFlag("help", "Print this message and exit", 'h');
    try parser.addOption("name", "Who to say hi to", null, null, null);

    var ags = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, ags);
    var results = try parser.parse(ags);
    defer results.deinit();

    if(results.flag != null and results.flag.?.get("help") != null) {
        try parser.help();
    } else {
        if(results.option) |op| {
            if(op.get("name")) |name| {
                std.debug.print("Hi {s}\n", .{ name });
            }
        } else {
            std.debug.print("Hi\n", .{});
        }
    }
}
```

```sh
$ zig build run
Hi
$ zig build run -- --name Joe
Hi Joe
$ zig build run -- -h
hi - Say hi

FLAGS
    --help, -h
        Print this message and exit

OPTIONS
    --name
        Who to say hi to

```
