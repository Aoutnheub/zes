# Parser

## Error types

```zig
ParseError = error {
    InvalidArgument,
    InvalidValue,
    MissingValue,
} || std.mem.Allocator.Error || std.fmt.BufPrintError
```

```zig
ArgError = error {
    DuplicateArgument
} || std.mem.Allocator.Error || std.fmt.BufPrintError
```

## Fields

```zig
err: ?[]const u8 = null
```

Error messages

```zig
allocator: std.mem.Allocator
```

```zig
command_required: bool = false
```

Return an error if the first argument isn't a command. Ignored if no commands have been added

```zig
commands_help_msg: []const u8 = "COMMANDS"
```

Header displayed by the `help` function before the command descriptions

```zig
flags_help_msg: []const u8 = "FLAGS"
```

Header displayed by the `help` function before the flag descriptions

```zig
options_help_msg: []const u8 = "OPTIONS"
```

Header displayed by the `help` function before the option descriptions

```zig
colors: bool = false
```

Color the output of the `help` function

```zig
title_color: ANSICode = ANSIGreen
```

Color of the title outputed by the `help` function

```zig
description_color: ANSICode = ANSIWhite
```

Color of the description outputed by the `help` function

```zig
header_color: ANSICode = ANSIRed
```

Color of the headers outputed by the `help` function

```zig
command_color: ANSICode = ANSIMagenta
```

Color of the command names outputed by the `help` function

```zig
command_description_color: ANSICode = ANSIWhite
```

Color of the command's description outputed by the `help` function

```zig
flag_color: ANSICode = ANSIBlue
```

Color of the flag names outputed by the `help` function

```zig
flag_description_color: ANSICode = ANSIWhite
```

Color of the flag's description outputed by the `help` function

```zig
option_color: ANSICode = ANSIBlue
```

Color of the option names outputed by the `help` function

```zig
option_description_color: ANSICode = ANSIWhite
```

Color of the option's description outputed by the `help` function

```zig
option_allowed_color: ANSICode = ANSIYellow
```

Color of the option's allowed values outputed by the `help` function


## Functions

```zig
fn init(allocator: std.mem.Allocator, name: []const u8, description: []const u8) Parser
```

```zig
fn deinit(self: *Parser) void
```

```zig
fn addFlag(self: *Parser, name: []const u8, help_: []const u8, abbr: ?u8) !void
```

Add a flag

- `name` : flag's name
- `help` : flag's description
- `abbr` : flag's abbreviation
- Error types
  - `ParserError.DuplicateArgument` : `err` field contains the duplicate argument
  - `Allocator.Error`
  - `BufPrintError`

```zig
fn addOption(
    self: *Parser, name: []const u8, help_: []const u8, abbr: ?u8,
    defaults_to: ?[]const u8, allowed: ?std.ArrayList([]const u8)
) !void
```

Add an option

- `name` : option's name
- `help` : option's description
- `abbr` : option's abbreviation
- `defaults_to` : option's default value
- `allowed` : option's allowed values. Doesn't necessarily need to contain the default value
- Error types
  - `ParserError.DuplicateArgument` : `err` field contains the duplicate argument
  - `Allocator.Error`
  - `BufPrintError`

```zig
fn addCommand(self: *Parser, name: []const u8, help_: []const u8) !void
```

Add a command

- `name` : command's name
- `help` : command's description
- Error types
  - `ParserError.DuplicateArgument` : `err` field contains the duplicate argument
  - `Allocator.Error`
  - `BufPrintError`

```zig
fn help(self: *Parser) !void
```

Display the help message

```zig
fn parse(self: *Parser, args: [][:0]u8) !Results
```

Parse the command line arguments

- `args` : arguments

- Error types
  - `ParserError.InvalidArgument` : `err` field contains the invalid argument
  - `ParserError.InvalidValue` : `err` field contains the option with an invalid value
  - `ParserError.MissingValue` : `err` field contains the option missing a value
  - `Allocator.Error`
  - `BufPrintError`

Returns a `Results` type with the parsed arguments or error
