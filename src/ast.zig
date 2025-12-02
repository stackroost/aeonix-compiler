const std = @import("std");

pub const StatementEmit = struct {
    msg: []const u8,
    newline: bool,
};

pub const Ast = struct {
    stmts: std.ArrayList(StatementEmit),

    pub fn init() !Ast {
        return Ast{ .stmts = try std.ArrayList(StatementEmit).initCapacity(std.heap.page_allocator, 0) };
    }

    pub fn addStatement(self: *Ast, s: StatementEmit) !void {
        try self.stmts.append(std.heap.page_allocator, s);
    }
};
