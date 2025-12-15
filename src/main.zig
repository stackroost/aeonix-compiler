const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // DEFAULT RUN → SHOW HELP
    if (args.len == 1) {
        printHelp();
        return;
    }

    const cmd = args[1];

    if (std.mem.eql(u8, cmd, "help")) {
        printHelp();
    } else if (std.mem.eql(u8, cmd, "build")) {
        std.debug.print("build not implemented yet\n", .{});
    } else if (std.mem.eql(u8, cmd, "run")) {
        std.debug.print("run not implemented yet\n", .{});
    } else if (std.mem.eql(u8, cmd, "check")) {
        std.debug.print("check not implemented yet\n", .{});
    } else if (std.mem.eql(u8, cmd, "ir")) {
        std.debug.print("ir not implemented yet\n", .{});
    } else {
        std.debug.print("Unknown command\n\n", .{});
        printHelp();
    }
}

fn printHelp() void {
    std.debug.print(
        \\ZING — Aeonix Compiler v0.1
        \\
        \\Usage:
        \\  zing build <file.aex>      Compile Aeonix source
        \\  zing run <file.aex>        Compile and execute
        \\  zing check <file.aex>      Syntax and verifier checks
        \\  zing ir <file.aex>         Emit intermediate representation
        \\  zing help                 Show command help
        \\
    , .{});
}
