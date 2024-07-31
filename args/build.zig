const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "args",
        .root_source_file = .{
            .src_path = .{
                .owner = b,
                .sub_path = "src/main.zig"
            }
        },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib);

    const mod = b.createModule(.{
        .root_source_file = .{
            .src_path = .{
                .owner = b,
                .sub_path = "src/main.zig"
            }
        }
    });

    const main_tests = b.addTest(.{
        .root_source_file = .{
            .src_path = .{
                .owner = b,
                .sub_path = "src/test.zig"
            }
        },
        .target = target,
        .optimize = optimize,
    });
    main_tests.root_module.addImport("args", mod);
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
