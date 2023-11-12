const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "args",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib);

    const mod = b.createModule(.{ .source_file = .{ .path = "src/main.zig" } });

    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/test.zig" },
        .target = target,
        .optimize = optimize,
    });
    main_tests.addModule("args", mod);
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
