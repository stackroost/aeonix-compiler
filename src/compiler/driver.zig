const std = @import("std");
const Lexer = @import("../lexer.zig");
const Parser = @import("../parser.zig");
const Codegen = @import("../codegen/x86_64.zig");

pub fn compile(path: []const u8) !void {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const size = try file.getEndPos();
    const buf = try std.heap.page_allocator.alloc(u8, size);
    defer std.heap.page_allocator.free(buf);

    _ = try file.readAll(buf);

    const tokens = try Lexer.tokenize(buf);
    const ast = try Parser.parse(tokens);
    try Codegen.codegen(ast);

    std.debug.print("aeonix: compiled {s}\n", .{path});
}
