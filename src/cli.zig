const std = @import("std");

pub fn printWelcomeAndHelp() void {
    // 0.15.x: buffered writer + interface pointer
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const out = &stdout_writer.interface;
    defer out.flush() catch {};

    // ANSI colours
    const reset   = "\x1b[0m";
    const bold    = "\x1b[1m";
    const cyan    = "\x1b[36m";
    const green   = "\x1b[32m";
    const yellow  = "\x1b[33m";
    const magenta = "\x1b[35m";

    out.print(
        \\{s}{s}welcome to solnix ebpf tool{s}
        \\{s}--------------------------------{s}
        \\
        \\
    , .{ bold, cyan, reset, magenta, reset }) catch return;

    out.print(
        \\{s}Usage:{s}
        \\  solnix {s}build{s}  <file.snx> [-o out.o]
        \\  solnix {s}check{s}  <file.snx>
        \\  solnix {s}ir{s}     <file.snx>
        \\  solnix {s}run{s}    <file.snx>
        \\  solnix {s}help{s}
        \\
        \\
    , .{ yellow, reset, green, reset, green, reset, green, reset, green, reset, green, reset }) catch return;

    out.print(
        \\{s}Tip:{s} Start with:
        \\  solnix build examples/xdp_pass.snx -o xdp_pass.o
        \\
    , .{ yellow, reset }) catch return;
}

pub fn printHelp() void {
    printWelcomeAndHelp();
}

pub fn fail(msg: []const u8) noreturn {
    var stderr_buffer: [1024]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&stderr_buffer);
    const err = &stderr_writer.interface;

    err.print("\x1b[31merror:\x1b[0m {s}\n", .{msg}) catch {};
    err.flush() catch {}; // important in 0.15.x
    std.process.exit(1);
}
