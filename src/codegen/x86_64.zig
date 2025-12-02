const std = @import("std");
const Ast = @import("../ast.zig");
const ElfWriter = @import("../elf/writer.zig");

pub fn codegen(ast: Ast.Ast) !void {
    // For now: simple behavior - gather emit statements and join messages into a single program.
    var msgs = try std.ArrayList([]const u8).initCapacity(std.heap.page_allocator, 0);
    defer msgs.deinit(std.heap.page_allocator);

    for (ast.stmts.items) |s| {
        try msgs.append(std.heap.page_allocator, s.msg);
        if (s.newline) {
            try msgs.append(std.heap.page_allocator, &[_]u8{'\n'});
        }
    }

    // For simplicity use only first message combined
    const combined = std.mem.concat(std.heap.page_allocator, u8, msgs.items) catch return;

    defer std.heap.page_allocator.free(combined);

    try ElfWriter.write_executable(combined);
}
