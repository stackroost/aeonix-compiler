const std = @import("std");
const Ast = @import("../ast.zig");
const ElfWriter = @import("../elf/writer.zig");

pub fn codegen(ast: Ast.Ast) !void {
    // For now: simple behavior - gather emit statements and join messages into a single program.
    var msgs = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer msgs.deinit();

    for (ast.stmts.items) |s| {
        try msgs.append(s.msg);
        if (s.newline) {
            try msgs.append(&[_]u8{'\n'});
        }
    }

    // For simplicity use only first message combined
    var combined = std.mem.concat(std.heap.page_allocator, msgs.items) catch |_| return;

    defer std.heap.page_allocator.free(combined);

    try ElfWriter.write_executable(combined);
}
