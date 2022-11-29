const std = @import("std");

pub const ANSICode = *const [5:0]u8;

pub const ANSIDefault: ANSICode = "\x1b[39m";
pub const ANSIBGDefault: ANSICode = "\x1b[49m";
pub const ANSIBlack: ANSICode = "\x1b[30m";
pub const ANSIRed: ANSICode = "\x1b[31m";
pub const ANSIGreen: ANSICode = "\x1b[32m";
pub const ANSIYellow: ANSICode = "\x1b[33m";
pub const ANSIBlue: ANSICode = "\x1b[34m";
pub const ANSIMagenta: ANSICode = "\x1b[35m";
pub const ANSICyan: ANSICode = "\x1b[36m";
pub const ANSIWhite: ANSICode = "\x1b[37m";
pub const ANSIBGBlack: ANSICode = "\x1b[40m";
pub const ANSIBGRed: ANSICode = "\x1b[41m";
pub const ANSIBGGreen: ANSICode = "\x1b[42m";
pub const ANSIBGYellow: ANSICode = "\x1b[43m";
pub const ANSIBGBlue: ANSICode = "\x1b[44m";
pub const ANSIBGMagenta: ANSICode = "\x1b[45m";
pub const ANSIBGCyan: ANSICode = "\x1b[46m";
pub const ANSIBGWhite: ANSICode = "\x1b[47m";

pub const Results = struct {
    flag: ?std.hash_map.StringHashMap(bool),
    option: ?std.hash_map.StringHashMap([]const u8),
    positional: ?std.ArrayList([]const u8),
    command: ?[]u8,
};

const Option = struct {
    help: []const u8,
    defaults_to: []const u8,
    allowed: ?std.ArrayList([]const u8),

    pub fn init() Option {
        return Option{
            .help = "",
            .defaults_to = "",
            .allowed = null,
        };
    }

    pub fn deinit(self: *Option) void {
        self.allowed.deinit();
    }
};

pub const ParserError = error{
    DuplicateArgument,
    InvalidArgument,
    InvalidValue,
    MissingValue,
};

pub const Parser = struct {
    // Everything with _ at the start is internal stuff.
    // Changing values manually may cause pain, bleeding or even death
    _flags: std.hash_map.StringHashMap([]const u8),
    _flags_abbr: std.array_hash_map.AutoArrayHashMap(u8, []const u8),
    _options: std.hash_map.StringHashMap(Option),
    _options_abbr: std.array_hash_map.AutoArrayHashMap(u8, []const u8),
    _commands: std.hash_map.StringHashMap([]const u8),
    _name: []const u8,
    _description: []const u8,
    allocator: std.mem.Allocator,
    command_required: bool,
    commands_help_msg: []const u8,
    flags_help_msg: []const u8,
    options_help_msg: []const u8,
    colors: bool,
    title_color: ANSICode,
    description_color: ANSICode,
    header_color: ANSICode,
    command_color: ANSICode,
    command_description_color: ANSICode,
    flag_color: ANSICode,
    flag_description_color: ANSICode,
    option_color: ANSICode,
    option_description_color: ANSICode,
    option_allowed_color: ANSICode,

    fn getFlagsAbbr(self: *Parser) !std.array_hash_map.StringArrayHashMap(u8) {
        var abbr = std.array_hash_map.StringArrayHashMap(u8).init(self.allocator);
        var flags_abbr_iter = self._flags_abbr.iterator();
        while(flags_abbr_iter.next()) |entry| {
            try abbr.put(entry.value_ptr.*, entry.key_ptr.*);
        }

        return abbr;
    }

    fn getOptionsAbbr(self: *Parser) !std.array_hash_map.StringArrayHashMap(u8) {
        var abbr = std.array_hash_map.StringArrayHashMap(u8).init(self.allocator);
        var options_abbr_iter = self._options_abbr.iterator();
        while(options_abbr_iter.next()) |entry| {
            try abbr.put(entry.value_ptr.*, entry.key_ptr.*);
        }

        return abbr;
    }

    fn isAllowedOptionValue(self: Parser, opt: []const u8, val: []const u8) bool {
        var option = self._options.get(opt);
        var allowed = false;
        if(option) |op| {
            if(op.allowed) |alw| {
                if(alw.items.len != 0) {
                    for(alw.items) |itm| {
                        if(std.mem.eql(u8, itm, val)) {
                            allowed = true;
                            break;
                        }
                    }
                } else {
                    allowed = true;
                }
            } else {
                return true;
            }
        }

        return allowed;
    }

    pub fn init(allocator: std.mem.Allocator, name: []const u8, description: []const u8) Parser {
        return Parser{
            ._name = name,
            ._description = description,
            ._flags = std.hash_map.StringHashMap([]const u8).init(allocator),
            ._flags_abbr = std.array_hash_map.AutoArrayHashMap(u8, []const u8).init(allocator),
            ._options = std.hash_map.StringHashMap(Option).init(allocator),
            ._options_abbr = std.array_hash_map.AutoArrayHashMap(u8, []const u8).init(allocator),
            ._commands = std.hash_map.StringHashMap([]const u8).init(allocator),
            .allocator = allocator,
            .command_required = false,
            .commands_help_msg = "COMMANDS",
            .flags_help_msg = "FLAGS",
            .options_help_msg = "OPTIONS",
            .colors = false,
            .title_color = ANSIGreen,
            .description_color = ANSIWhite,
            .header_color = ANSIRed,
            .command_color = ANSIMagenta,
            .command_description_color = ANSIWhite,
            .flag_color = ANSIBlue,
            .flag_description_color = ANSIWhite,
            .option_color = ANSIBlue,
            .option_description_color = ANSIWhite,
            .option_allowed_color = ANSIYellow,
        };
    }

    pub fn deinit(self: *Parser) void {
        self._flags.deinit();
        self._flags_abbr.deinit();
        self._options.deinit();
        self._options_abbr.deinit();
        self._commands.deinit();
    }

    pub fn addFlag(self: *Parser, name: []const u8, help_: []const u8, abbr: ?u8) !void {
        if(!self._flags.contains(name) and !self._options.contains(name)) {
            if(abbr) |ab| {
                if(!self._flags_abbr.contains(ab) and !self._options_abbr.contains(ab)) {
                    try self._flags.put(name, help_);
                    try self._flags_abbr.put(ab, name);
                } else {
                    return ParserError.DuplicateArgument;
                }
            } else {
                try self._flags.put(name, help_);
            }
        } else {
            return ParserError.DuplicateArgument;
        }
    }

    pub fn addOption(self: *Parser, name: []const u8, help_: []const u8, abbr: ?u8, defaults_to: []const u8, allowed: ?std.ArrayList([]const u8)) !void {
        if(!self._flags.contains(name) and !self._options.contains(name)) {
            if(abbr) |ab| {
                if(!self._flags_abbr.contains(ab) and !self._options_abbr.contains(ab)) {
                    try self._options.put(name, Option{ .help = help_, .defaults_to = defaults_to, .allowed = allowed });
                    try self._options_abbr.put(ab, name);
                } else {
                    return ParserError.DuplicateArgument;
                }
            } else {
                try self._options.put(name, Option{ .help = help_, .defaults_to = defaults_to, .allowed = allowed });
            }
        } else {
            return ParserError.DuplicateArgument;
        }
    }

    pub fn addCommand(self: *Parser, name: []const u8, help_: []const u8) !void {
        if(!self._commands.contains(name)) {
            try self._commands.put(name, help_);
        } else {
            return ParserError.DuplicateArgument;
        }
    }

    pub fn help(self: *Parser) !void {
        const cout = std.io.getStdOut();
        if(!std.mem.eql(u8, self._name, "")) {
            if(self.colors) { _ = try cout.write(self.title_color); }
            _ = try cout.write(self._name);
            if(self.colors) { _ = try cout.write("\x1b[0m"); }
        }
        if(!std.mem.eql(u8, self._description, "")) {
            if(self.colors) { _ = try cout.write(self.description_color); }
            _ = try cout.write(" - ");
            var indent = std.mem.zeroes([64:0]u8);
            var indent_size = self._name.len + 3;
            if(indent_size > 64) { indent_size = 64; }
            while(indent_size > 0) {
                indent[indent_size - 1] = ' ';
                indent_size -= 1;
            }
            var token = std.mem.indexOf(u8, self._description, "\n");
            if(token != null) {
                var last: usize = 0;
                while(token) |tk| {
                    if(last == 0) {
                        _ = try cout.write(self._description[last..tk + 1]);
                    } else {
                        _ = try cout.write(&indent);
                        _ = try cout.write(self._description[last..tk + 1]);
                        _ = try cout.write("\n");
                    }
                    last = tk + 1;
                    token = std.mem.indexOf(u8, self._description[last..], "\n");
                }
                if(last < self._description.len - 1) {
                    _ = try cout.write(&indent);
                    _ = try cout.write(self._description[last..]);
                    _ = try cout.write("\n");
                }
            } else {
                _ = try cout.write(self._description);
            }
            if(self.colors) { _ = try cout.write("\x1b[0m"); }
        }
        _ = try cout.write("\n");

        if(self._commands.count() != 0) {
            if(!std.mem.eql(u8, self.commands_help_msg, "")) {
                if(self.colors) { _ = try cout.write(self.header_color); }
                _ = try cout.write(self.commands_help_msg);
                if(self.colors) { _ = try cout.write("\x1b[0m"); }
                _ = try cout.write("\n");
            }
            var commands_iter = self._commands.iterator();
            while(commands_iter.next()) |entry| {
                if(self.colors) { _ = try cout.write(self.command_color); }
                _ = try cout.write("    ");
                _ = try cout.write(entry.key_ptr.*);
                if(self.colors) { _ = try cout.write("\x1b[0m"); }
                _ = try cout.write("\n");
                var indent = "        ";
                if(!std.mem.eql(u8, entry.value_ptr.*, "")) {
                    if(self.colors) { _ = try cout.write(self.command_description_color); }
                    var token = std.mem.indexOf(u8, entry.value_ptr.*, "\n");
                    if(token != null) {
                        var last: usize = 0;
                        while(token) |tk| {
                            _ = try cout.write(indent);
                            _ = try cout.write(entry.value_ptr.*[last..tk + 1]);
                            _ = try cout.write("\n");
                            last = tk + 1;
                            token = std.mem.indexOf(u8, entry.value_ptr.*[last..], "\n");
                        }
                        if(last < entry.value_ptr.*.len - 1) {
                            _ = try cout.write(indent);
                            _ = try cout.write(entry.value_ptr.*[last..]);
                            _ = try cout.write("\n");
                        }
                    } else {
                        _ = try cout.write(indent);
                        _ = try cout.write(entry.value_ptr.*);
                        _ = try cout.write("\n");
                    }
                    if(self.colors) { _ = try cout.write("\x1b[0m"); }
                }
                _ = try cout.write("\n");
            }
        }

        if(self._flags.count() != 0) {
            var abbr = try self.getFlagsAbbr();
            if(!std.mem.eql(u8, self.flags_help_msg, "")) {
                if(self.colors) { _ = try cout.write(self.header_color); }
                _ = try cout.write(self.flags_help_msg);
                if(self.colors) { _ = try cout.write("\x1b[0m"); }
                _ = try cout.write("\n");
            }
            var flags_iter = self._flags.iterator();
            while(flags_iter.next()) |entry| {
                if(self.colors) { _ = try cout.write(self.flag_color); }
                _ = try cout.write("    --");
                _ = try cout.write(entry.key_ptr.*);
                var tmp = abbr.get(entry.key_ptr.*);
                if(tmp != null) { _ = try cout.write(", -"); _ = try cout.write(&[_]u8{tmp.?}); }
                if(self.colors) { _ = try cout.write("\x1b[0m"); }
                _ = try cout.write("\n");
                var indent = "        ";
                if(!std.mem.eql(u8, entry.value_ptr.*, "")) {
                    if(self.colors) { _ = try cout.write(self.flag_description_color); }
                    var token = std.mem.indexOf(u8, entry.value_ptr.*, "\n");
                    if(token != null) {
                        var last: usize = 0;
                        while(token) |tk| {
                            _ = try cout.write(indent);
                            _ = try cout.write(entry.value_ptr.*[last..tk + 1]);
                            _ = try cout.write("\n");
                            last = tk + 1;
                            token = std.mem.indexOf(u8, entry.value_ptr.*[last..], "\n");
                        }
                        if(last < entry.value_ptr.*.len - 1) {
                            _ = try cout.write(indent);
                            _ = try cout.write(entry.value_ptr.*[last..]);
                            _ = try cout.write("\n");
                        }
                    } else {
                        _ = try cout.write(indent);
                        _ = try cout.write(entry.value_ptr.*);
                        _ = try cout.write("\n");
                    }
                    if(self.colors) { _ = try cout.write("\x1b[0m"); }
                }
                _ = try cout.write("\n");
            }
        }

        if(self._options.count() != 0) {
            var abbr = try self.getOptionsAbbr();
            if(!std.mem.eql(u8, self.options_help_msg, "")) {
                if(self.colors) { _ = try cout.write(self.header_color); }
                _ = try cout.write(self.options_help_msg);
                if(self.colors) { _ = try cout.write("\x1b[0m"); }
                _ = try cout.write("\n");
            }
            var options_iter = self._options.iterator();
            while(options_iter.next()) |entry| {
                if(self.colors) { _ = try cout.write(self.option_color); }
                _ = try cout.write("    --");
                _ = try cout.write(entry.key_ptr.*);
                var tmp = abbr.get(entry.key_ptr.*);
                if(tmp != null) { _ = try cout.write(", -"); _ = try cout.write(&[_]u8{tmp.?}); }
                if(self.colors) { _ = try cout.write("\x1b[0m"); }
                if(entry.value_ptr.*.allowed != null) {
                    if(self.colors) { _ = try cout.write(self.option_allowed_color); }
                    _ = try cout.write(" ");
                    for(entry.value_ptr.*.allowed.?.items) |alw, idx| {
                        _ = try cout.write(alw);
                        if(idx != entry.value_ptr.*.allowed.?.items.len - 1) {
                            _ = try cout.write("|");
                        }
                    }
                    if(self.colors) { _ = try cout.write("\x1b[0m"); }
                }
                _ = try cout.write("\n");
                var indent = "        ";
                if(!std.mem.eql(u8, entry.value_ptr.*.help, "")) {
                    if(self.colors) { _ = try cout.write(self.option_description_color); }
                    var token = std.mem.indexOf(u8, entry.value_ptr.*.help, "\n");
                    if(token != null) {
                        var last: usize = 0;
                        while(token) |tk| {
                            _ = try cout.write(indent);
                            _ = try cout.write(entry.value_ptr.*.help[last..tk + 1]);
                            last = tk + 1;
                            token = std.mem.indexOf(u8, entry.value_ptr.*.help[last..], "\n");
                        }
                        if(last < entry.value_ptr.*.help.len - 1) {
                            _ = try cout.write(indent);
                            _ = try cout.write(entry.value_ptr.*.help[last..]);
                            _ = try cout.write("\n");
                        }
                    } else {
                        _ = try cout.write(indent);
                        _ = try cout.write(entry.value_ptr.*.help);
                        _ = try cout.write("\n");
                    }
                    if(self.colors) { _ = try cout.write("\x1b[0m"); }
                }
                _ = try cout.write("\n");
            }
        }
    }

    pub fn parse(self: *Parser, args: [][:0]u8) !Results {
        var results = Results{
            .flag = null,
            .option = null,
            .positional = std.ArrayList([]const u8).init(self.allocator),
            .command = null,
        };
        if(self._flags.count() != 0) {
            results.flag = std.hash_map.StringHashMap(bool).init(self.allocator);
            var iter = self._flags.iterator();
            while(iter.next()) |entry| {
                try results.flag.?.put(entry.key_ptr.*, false);
            }
        }
        if(self._options.count() != 0) {
            results.option = std.hash_map.StringHashMap([]const u8).init(self.allocator);
            var iter = self._options.iterator();
            while(iter.next()) |entry| {
                try results.option.?.put(entry.key_ptr.*, entry.value_ptr.*.defaults_to);
            }
        }

        var i: usize = 1;
        var skip_command_check = false;
        while(i < args.len) {
            if(!skip_command_check and i == 1 and self._commands.count() != 0) {
                if(self._commands.contains(args[i])) {
                    var cmd_cpy = try self.allocator.alloc(u8, args[i].len);
                    std.mem.copy(u8, cmd_cpy, args[i]);
                    results.command = cmd_cpy;
                    i += 1;
                } else {
                    if(self.command_required) {
                        return ParserError.InvalidArgument;
                    }
                }
                skip_command_check = true;
            } else {
                if(std.mem.eql(u8, args[i], "--")) {
                    for(args) |val| {
                        try results.positional.?.append(val);
                    }
                    i = args.len;
                } else {
                    if(args[i].len > 2) {
                        if(args[i][0] == '-' and args[i][1] != '-') {
                            var equals = std.mem.indexOf(u8, args[i], "=");
                            if(equals != null) {
                                if(equals.? == 2) { // option
                                    var op = self._options_abbr.get(args[i][1]);
                                    if(op != null) {
                                        if(args[i].len > 3) {
                                            var tmp = args[i][3..];
                                            if(self.isAllowedOptionValue(op.?, tmp)) {
                                                try results.option.?.put(op.?, tmp);
                                                i += 1;
                                            } else {
                                                return ParserError.InvalidValue;
                                            }
                                        } else {
                                            return ParserError.MissingValue;
                                        }
                                    }
                                } else { // multiple flags and one option
                                    var ii: usize = 1;
                                    while(ii < equals.? - 1) {
                                        var fl = self._flags_abbr.get(args[i][ii]);
                                        if(fl != null) {
                                            try results.flag.?.put(fl.?, true);
                                        } else {
                                            return ParserError.InvalidArgument;
                                        }
                                        ii += 1;
                                    }
                                    if(equals.? + 1 < args[i].len) {
                                        var op = self._options_abbr.get(args[i][equals.? - 1]);
                                        if(op != null) {
                                            var tmp = args[i][equals.? + 1..];
                                            if(self.isAllowedOptionValue(op.?, tmp)) {
                                                try results.option.?.put(op.?, tmp);
                                            } else {
                                                return ParserError.MissingValue;
                                            }
                                        }
                                    } else {
                                        return ParserError.MissingValue;
                                    }
                                    i += 1;
                                }
                            } else { // option and value with no space
                                var op = self._options_abbr.get(args[i][1]);
                                if(op != null) {
                                    var tmp = args[i][2..];
                                    if(self.isAllowedOptionValue(op.?, tmp)) {
                                        try results.option.?.put(op.?, tmp);
                                    } else {
                                        return ParserError.MissingValue;
                                    }
                                } else { // multiple flags
                                    var ii: usize = 1;
                                    while(ii < args[i].len) {
                                        var fl = self._flags_abbr.get(args[i][ii]);
                                        if(fl != null) {
                                            try results.flag.?.put(fl.?, true);
                                        } else {
                                            return ParserError.InvalidArgument;
                                        }
                                    }
                                }
                                i += 1;
                            }
                        } else if(args[i][0] == '-' and args[i][1] == '-') {
                            var equals = std.mem.indexOf(u8, args[i], "=");
                            if(equals != null) {
                                var op = args[i][2..equals.?];
                                var val: []u8 = undefined;
                                if(equals.? + 1 < args[i].len) {
                                    val = args[i][equals.? + 1..];
                                } else {
                                    return ParserError.MissingValue;
                                }
                                if(self.isAllowedOptionValue(op, val)) {
                                    try results.option.?.put(op, val);
                                } else {
                                    return ParserError.InvalidValue;
                                }
                                i += 1;
                            } else {
                                var arg = args[i][2..];
                                if(self._flags.contains(arg)) {
                                    try results.flag.?.put(arg, true);
                                    i += 1;
                                } else {
                                    if(self._options.contains(arg)) {
                                        if(i + 1 < args.len) {
                                            if(args[i + 1].len == 0) {
                                                try results.option.?.put(arg, args[i + 1]);
                                            } else {
                                                if(args[i + 1][0] != '-') {
                                                    if(self.isAllowedOptionValue(arg, args[i + 1])) {
                                                        try results.option.?.put(arg, args[i + 1]);
                                                    } else {
                                                        return ParserError.InvalidValue;
                                                    }
                                                } else {
                                                    return ParserError.MissingValue;
                                                }
                                            }
                                        } else {
                                            return ParserError.MissingValue;
                                        }
                                        i += 2;
                                    } else {
                                        return ParserError.InvalidArgument;
                                    }
                                }
                            }
                        } else {
                            try results.positional.?.append(args[i]);
                            i += 1;
                        }
                    } else if(args[i].len == 2) {
                        if(args[i][0] == '-') {
                            var fl = self._flags_abbr.get(args[i][1]);
                            if(fl != null) {
                                try results.flag.?.put(fl.?, true);
                                i += 1;
                            } else {
                                var op = self._options_abbr.get(args[i][1]);
                                if(op != null) {
                                    if(i + 1 < args.len) {
                                        if(args[i + 1].len == 0) {
                                            try results.option.?.put(op.?, args[i + 1]);
                                        } else {
                                            if(args[i + 1][0] != '-') {
                                                try results.option.?.put(op.?, args[i + 1]);
                                            } else {
                                                return ParserError.MissingValue;
                                            }
                                        }
                                    } else {
                                        return ParserError.MissingValue;
                                    }
                                    i += 2;
                                } else {
                                    return ParserError.InvalidArgument;
                                }
                            }
                        } else {
                            try results.positional.?.append(args[i]);
                            i += 1;
                        }
                    } else {
                        try results.positional.?.append(args[i]);
                        i += 1;
                    }
                }
            }
        }

        if(results.flag.?.count() == 0) {
            results.flag.?.deinit();
            results.flag = null;
        }
        if(results.option.?.count() == 0) {
            results.option.?.deinit();
            results.option = null;
        }
        if(results.positional.?.items.len == 0) {
            results.positional.?.deinit();
            results.positional = null;
        }

        return results;
    }
};
