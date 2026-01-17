const std = @import("std");

pub const IRUnit = struct {
    name: []const u8,
    sections: []const []const u8,
    license: ?[]const u8,
    return_value: i64,
};

pub fn lowerUnit(u: *const @import("../ast/unit.zig").Unit) IRUnit {
    var ret: i64 = 0;

    for (u.body) |stmt| {
        switch (stmt.kind) {
            .Return => |v| ret = v.kind.Number,
            .VarDecl => {},
            .IfGuard => {},
            .HeapVarDecl => {},
            .Assignment => {},
        }
    }

    return IRUnit{
        .name = u.name,
        .sections = u.sections,
        .license = u.license,
        .return_value = ret,
    };
}
