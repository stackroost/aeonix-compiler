const std = @import("std");
const Lexer = @import("../lexer.zig");
const Parser = @import("../parser.zig");
const Codegen = @import("../codegen/x86_64.zig");

pub fn compile(path: []const u8) !void {
    const buf = try std.fs.cwd().readFileAlloc(path, std.heap.page_allocator, .unlimited);
    defer std.heap.page_allocator.free(buf);

    const tokens = try Lexer.tokenize(buf);
    const ast = try Parser.parse(tokens);
    try Codegen.codegen(ast);

    std.debug.print("aeonix: compiled {s}\n", .{path});
}
