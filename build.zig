const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("solnix-compiler", .{
        .root_source_file = b.path("src/compiler.zig"),
        .target = b.resolveTargetQuery(target.query),
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .name = "solnix-compiler",
        .root_module = mod,
        .linkage = .static,
    });
    b.installArtifact(lib);
}
