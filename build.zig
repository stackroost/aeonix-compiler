const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // 1. Create the root module first.
    // In this build version, target and optimize are configured here on the module.
    const root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // 2. Add the executable, passing the required 'root_module' field.
    const exe = b.addExecutable(.{
        .name = "solnix",
        .root_module = root_module,
    });

    exe.linkLibC();
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |args| run_cmd.addArgs(args);

    const run_step = b.step("run", "Run solnix compiler");
    run_step.dependOn(&run_cmd.step);
}