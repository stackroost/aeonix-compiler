const std = @import("std");
const ast = @import("../ast/mod.zig");
const unit_ir = @import("unit.zig");

pub const IRProgram = struct {
    units: []unit_ir.IRUnit,
};

pub fn lowerProgram(program: *const ast.Program, allocator: std.mem.Allocator) !IRProgram {
    var units_list = try std.ArrayList(unit_ir.IRUnit).initCapacity(allocator, 0);

    for (program.units) |unit| {
        const lowered = unit_ir.lowerUnit(&unit);
        try units_list.append(allocator, lowered);
    }

    return IRProgram{
        .units = try units_list.toOwnedSlice(allocator),
    };
}
