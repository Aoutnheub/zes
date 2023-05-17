## Description

Command line argument parser.

## Example

```zig
const std = @import("std");
const args = @import("./args.zig");

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
        if(results.option != null) {
            const name = results.option.?.get("name");
            if(name) |n| {
                std.debug.print("Hi {s}\n", .{ n });
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

## Documentation

- [Color codes](#color-codes)
- [Error types](#error-types)
- [Results struct](#results-struct)
  - [Fields](#fields)
  - [Functions](#functions)
- [Parser struct](#parser-struct)
  - [Fields](#fields-1)
  - [Functions](#functions-1)

### Color codes

Used for coloring output of `Parser.help`

- FG
  - `ANSIDefault`
  - `ANSIBGDefault`
  - `ANSIBlack`
  - `ANSIRed`
  - `ANSIGreen`
  - `ANSIYellow`
  - `ANSIBlue`
  - `ANSIMagenta`
  - `ANSICyan`
  - `ANSIWhite`
- BG
  - `ANSIBGBlack`
  - `ANSIBGRed`
  - `ANSIBGGreen`
  - `ANSIBGYellow`
  - `ANSIBGBlue`
  - `ANSIBGMagenta`
  - `ANSIBGCyan`
  - `ANSIBGWhite`

### Error types

- DuplicateArgument
- InvalidArgument
- InvalidValue
- MissingValue

### Results struct

#### Fields

- `allocator: std.mem.Allocator`
- `flag: ?std.hash_map.StringHashMap(bool) = null` : Stores flag values after parsing
- `option: ?std.hash_map.StringHashMap([]const u8) = null` : Stores option values after parsing
- `positional: ?std.ArrayList([]const u8) = null` : Stores positional arguments after parsing
- `command: ?[]u8 = null` : Stores the command after parsing

#### Functions

- `fn deinit(self: *Results) void`

### Parser struct

#### Fields

- `err: ?[]const u8` : Error messages
- `allocator: std.mem.Allocator`
- `command_required: bool` : Return an error if the first argument isn't a command. Ignored if no commands have been added
- `commands_help_msg: []const u8` : Header displayed by the `help` function before the command descriptions
- `flags_help_msg: []const u8` : Header displayed by the `help` function before the flag descriptions
- `options_help_msg: []const u8` : Header displayed by the `help` function before the option descriptions
- `colors: bool` : Color the output of the `help` function
- `title_color: ANSICode` : Color of the title outputed by the `help` function
- `description_color: ANSICode` : Color of the description outputed by the `help` function
- `header_color: ANSICode` : Color of the headers outputed by the `help` function
- `command_color: ANSICode` : Color of the command names outputed by the `help` function
- `command_description_color: ANSICode` : Color of the command's description outputed by the `help` function
- `flag_color: ANSICode` : Color of the flag names outputed by the `help` function
- `flag_description_color: ANSICode` : Color of the flag's description outputed by the `help` function
- `option_color: ANSICode` : Color of the option names outputed by the `help` function
- `option_description_color: ANSICode` : Color of the option's description outputed by the `help` function
- `option_allowed_color: ANSICode` : Color of the option's allowed values outputed by the `help` function

#### Functions

- `fn init(allocator: std.mem.Allocator, name: []const u8, description: []const u8) Parser`

- `fn deinit(self: *Parser) void`

- `pub fn addFlag(self: *Parser, comptime name: []const u8, comptime help_: []const u8, comptime abbr: ?u8) !void` : Add a flag
  - `name` : flag's name
  - `help` : flag's description
  - `abbr` : (optional) flag's abbreviation
  - Error types
    - `ParserError.DuplicateArgument` : .err field contains the duplicate argument
    - `Allocator.Error`

- `fn addOption(self: *Parser, name: []const u8, help_: []const u8, abbr: ?u8, defaults_to: ?[]const u8, allowed: ?std.ArrayList([]const u8)) !void` : Add an option
  - `name` : option's name
  - `help` : option's description
  - `abbr` : (optional) option's abbreviation
  - `defaultsTo` option's default value
  - `allowed` : (optional) option's allowed values. Doesn't necessarily need to contain the default value
  - Error types
    - `ParserError.DuplicateArgument` : .err field contains the duplicate argument)
    - `Allocator.Error`

- `fn addCommand(self: *Parser, name: []const u8, help_: []const u8) !void` : Add a command
  - `name` : command's name
  - `help` : command's description
  - Error types
    - `ParserError.DuplicateArgument` : .err field contains the duplicate argument
    -` Allocator.Error`

- `fn help(self: *Parser) !void` : Display the help message

- `fn parse(self: *Parser, args: [][:0]u8) !Results` : Parse the command line arguments
  - Error types
    - `ParserError.InvalidArgument` : .err field contains the invalid argument
    - `ParserError.InvalidValue` : .err field contains the option with an invalid value
    - `ParserError.MissingValue` : .err field contains the option missing a value
    - `Allocator.Error`
