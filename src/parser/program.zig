const std = @import("std");
const ast = @import("../ast/mod.zig");
const Parser = @import("parser.zig").Parser;
const parseMap = @import("map.zig").parseMap;
const parseUnit = @import("unit.zig").parseUnit;

pub fn parseProgram(self: *Parser) Parser.ParseError!ast.Program {
    var maps: std.ArrayList(ast.MapDecl) = .empty;
    var units: std.ArrayList(ast.Unit) = .empty;

    errdefer maps.deinit(self.allocator);
    errdefer units.deinit(self.allocator);

    while (self.current.kind != .eof) {
        if (self.match(.keyword_map)) {
            const m = try parseMap(self);
            try maps.append(self.allocator, m);
        } else if (self.current.kind == .keyword_unit) {
            const u = try parseUnit(self);
            try units.append(self.allocator, u);
        } else {
            return self.parseError("expected 'map' or 'unit'");
        }
    }

    std.debug.print("[DEBUG] Parsed program with {d} maps and {d} units\n", .{ maps.items.len, units.items.len });

    return ast.Program{
        .maps = try maps.toOwnedSlice(self.allocator),
        .units = try units.toOwnedSlice(self.allocator),
    };
}
