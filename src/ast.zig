const std = @import("std");

pub const StatementEmit = struct {
    msg: []const u8,
    newline: bool,
};

pub const Ast = struct {
    stmts: std.ArrayList(StatementEmit),

    pub fn init() Ast {
        return Ast{ .stmts = std.ArrayList(StatementEmit).init(std.heap.page_allocator) };
    }

    pub fn addStatement(self: *Ast, s: StatementEmit) !void {
        try self.stmts.append(s);
    }
};
