const std = @import("std");
const compiler = @import("compiler.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 5 or
        !std.mem.eql(u8, args[1], "compile") or
        !std.mem.eql(u8, args[3], "-o"))
    {
        printUsage();
        std.process.exit(1);
    }

    const input_path = args[2];
    const output_path = args[4];

    const file = std.fs.cwd().openFile(input_path, .{}) catch {
        std.log.err("Input file not found: {s}", .{input_path});
        std.process.exit(1);
    };
    defer file.close();

    const src = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(src);

    compiler.compile(allocator, src, output_path) catch |err| {
        std.log.err("Compilation failed: {any}", .{err});
        std.process.exit(1);
    };
}

fn printUsage() void {
    std.log.err(
        "Usage:\n" ++
        "  solnix-compiler compile <input.snx> -o <output.o>",
        .{},
    );
}
