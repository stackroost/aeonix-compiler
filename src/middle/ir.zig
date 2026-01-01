const std = @import("std");
const parser = @import("../frontend/parser.zig");

pub const IR = struct {
    pub fn deinit(self: *IR, alloc: std.mem.Allocator) void {
        _ = self; _ = alloc;
    }
    pub fn dump(self: *IR, out: anytype) !void {
        _ = self;
        try out.print("; IR dump (stage-0 placeholder)\n", .{});
    }
};

pub fn fromAst(alloc: std.mem.Allocator, ast: *parser.Ast) !IR {
    _ = alloc; _ = ast;
    return IR{};
}
