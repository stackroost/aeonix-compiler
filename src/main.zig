const std = @import("std");
const Lexer = @import("lexer.zig");
const Parser = @import("parser.zig");
const Codegen = @import("codegen/x86_64.zig");

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    const path = if (args.len >= 2) args[1] else "examples/hello.aex";
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    const size = try file.getEndPos();
    const buf = std.heap.page_allocator.alloc(u8, @intCast(size)) catch {
        std.debug.print("alloc failed\n", .{});
        return;
    };
    defer std.heap.page_allocator.free(buf);

    _ = try file.read(buf);

    const tokens = try Lexer.tokenize(buf);
    const ast = try Parser.parse(tokens);
    try Codegen.codegen(ast);

    std.debug.print("aeonix: compiled {s}\n", .{path});
}
