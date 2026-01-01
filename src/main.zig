const std = @import("std");
const cli = @import("cli.zig");
const compiler = @import("compiler.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var args_it = try std.process.argsWithAllocator(alloc);
    defer args_it.deinit();

    // skip argv[0]
    _ = args_it.next();

    const cmd_opt = args_it.next();
    if (cmd_opt == null) {
        cli.printWelcomeAndHelp();
        return;
    }

    const cmd = cmd_opt.?;

    if (std.mem.eql(u8, cmd, "help") or std.mem.eql(u8, cmd, "--help") or std.mem.eql(u8, cmd, "-h")) {
        cli.printHelp();
        return;
    }

    if (std.mem.eql(u8, cmd, "build")) {
        const in_file = args_it.next() orelse return cli.fail("Missing input file. Usage: solnix build <file.snx> [-o out.o]");
        var out_file: ?[]const u8 = null;

        while (args_it.next()) |a| {
            if (std.mem.eql(u8, a, "-o")) {
                out_file = args_it.next() orelse return cli.fail("Missing value after -o");
            } else {
                return cli.fail("Unknown option for build");
            }
        }

        try compiler.compileFile(alloc, .build, in_file, out_file);
        return;
    }

    if (std.mem.eql(u8, cmd, "check")) {
        const in_file = args_it.next() orelse return cli.fail("Missing input file. Usage: solnix check <file.snx>");
        try compiler.compileFile(alloc, .check, in_file, null);
        return;
    }

    if (std.mem.eql(u8, cmd, "ir")) {
        const in_file = args_it.next() orelse return cli.fail("Missing input file. Usage: solnix ir <file.snx>");
        try compiler.compileFile(alloc, .emit_ir, in_file, null);
        return;
    }

    if (std.mem.eql(u8, cmd, "run")) {
        const in_file = args_it.next() orelse return cli.fail("Missing input file. Usage: solnix run <file.snx>");
        // Stage-0: compile only (later: load+attach)
        try compiler.compileFile(alloc, .run, in_file, null);
        return;
    }

    return cli.fail("Unknown command. Try: solnix help");
}
