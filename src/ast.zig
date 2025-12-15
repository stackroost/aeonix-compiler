const std = @import("std");

pub const StatementEmit = struct {
    msg: []const u8,
    newline: bool,
};

pub const Ast = struct {
    unit_name: []const u8,
    stmts: std.ArrayList(StatementEmit),

    pub fn init(unit_name: []const u8) !Ast {
        return Ast{ .unit_name = unit_name, .stmts = try std.ArrayList(StatementEmit).initCapacity(std.heap.page_allocator, 0) };
    }

    pub fn addStatement(self: *Ast, s: StatementEmit) !void {
        try self.stmts.append(std.heap.page_allocator, s);
    }
};
