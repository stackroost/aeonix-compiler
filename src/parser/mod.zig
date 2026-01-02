const std = @import("std");
const Parser = @import("parser.zig").Parser;
const ast = @import("../ast/unit.zig");

pub fn parse(src: []const u8, allocator: std.mem.Allocator) !ast.Unit {
    var p = try Parser.init(src, allocator);
    defer p.deinit();

    return try p.parseUnit();
}
