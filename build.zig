const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const compiler_mod = b.addModule("solnix-compiler", .{
        .root_source_file = b.path("src/compiler.zig"),
        .target = b.resolveTargetQuery(target.query),
        .optimize = optimize,
    });

    const compiler_lib = b.addLibrary(.{
        .name = "solnix-compiler",
        .root_module = compiler_mod,
        .linkage = .static, 
    });

    b.installArtifact(compiler_lib);
}
