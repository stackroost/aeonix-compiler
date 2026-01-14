const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "solnix-compiler",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    exe.linkLibC();
    exe.addIncludePath(.{ .cwd_relative = "/usr/lib/llvm-21/include" });
    exe.addLibraryPath(.{ .cwd_relative = "/usr/lib/llvm-21/lib" });
    exe.addRPath(.{ .cwd_relative = "/usr/lib/llvm-21/lib" });

    exe.linkSystemLibrary("LLVM-21");

    b.installArtifact(exe);
}
