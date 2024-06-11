const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "server",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize
    });

    b.installArtifact(lib);

    // const main_tests = b.addTest(.{
    //     .root_source_file = .{ .path = "src/test.zig" },
    //     .target = target,
    //     .optimize = optimize
    // });

    // const run_main_tests = b.addRunArtifact(main_tests);

    // const test_step = b.step("test", "Run library tests");
    // test_step.dependOn(&run_main_tests.step);

    const mod = b.createModule(.{ .source_file = .{ .path = "src/main.zig" } });

    // Examples
    var ex_dir = try std.fs.cwd().openIterableDir("src/examples", .{});
    defer ex_dir.close();
    var ex_dir_iter = ex_dir.iterate();
    while(try ex_dir_iter.next()) |entry| {
        const name = try std.fmt.allocPrint(std.heap.page_allocator, "example-{s}", .{ entry.name[0..std.mem.indexOf(u8, entry.name, ".zig").?] });
        const exe = b.addExecutable(.{
            .name = name,
            .root_source_file = .{ .path = try std.fmt.allocPrint(std.heap.page_allocator, "src/examples/{s}", .{ entry.name }) },
            .target = target,
            .optimize = optimize
        });
        exe.addModule("Server", mod);

        b.installArtifact(exe);

        const example_cmd = b.addRunArtifact(exe);
        example_cmd.step.dependOn(b.getInstallStep());

        const example_step = b.step(name, "Run the example");
        example_step.dependOn(&example_cmd.step);
    }
}
