const std = @import("std");

pub const Ast = struct {
    pub fn deinit(self: *Ast, alloc: std.mem.Allocator) void {
        _ = self; _ = alloc;
    }
};

pub fn parse(alloc: std.mem.Allocator, src: []const u8, tokens: []const @import("lexer.zig").Token) !Ast {
    _ = alloc; _ = src; _ = tokens;
    return Ast{};
}
