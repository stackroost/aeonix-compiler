const std = @import("std");

pub const IRUnit = struct {
    return_value: i64,
};

pub fn lowerUnit(u: *const @import("../ast/unit.zig").Unit) IRUnit {
    for (u.body) |stmt| {
        switch (stmt.kind) {
            .Return => |v| {
                return IRUnit{ .return_value = v };
            },
            .VarDecl => {
                continue;
            },
            .IfGuard => {
                continue;
            },
            .HeapVarDecl => {
                continue;
            },
        }
    }
    return IRUnit{ .return_value = 0 };
}
