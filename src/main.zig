const std = @import("std");
const Driver = @import("compiler/driver.zig");

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len == 1) {
        printHelp();
        return;
    }

    const cmd = args[1];

    if (std.mem.eql(u8, cmd, "run")) {
        if (args.len < 3) {
            std.debug.print("error: no input file\n", .{});
            return;
        }
        try Driver.compile(args[2]);
    } else if (std.mem.eql(u8, cmd, "build")) {
        if (args.len < 3) {
            std.debug.print("error: no input file\n", .{});
            return;
        }
        try Driver.compile(args[2]);
    } else {
        printHelp();
    }
}

fn printHelp() void {
    std.debug.print(
        \\aeonix — Aeonix Compiler v0.1
        \\
        \\Usage:
        \\  aeonix build <file.aex>      Compile Aeonix source
        \\  aeonix run <file.aex>        Compile and execute
        \\  aeonix check <file.aex>      Syntax and verifier checks
        \\  aeonix ir <file.aex>         Emit intermediate representation
        \\  aeonix help                 Show command help
        \\
    , .{});
}
