const std = @import("std");

pub const IRUnit = struct {
    return_value: i64,
};

pub fn lowerUnit(u: *const @import("../ast/unit.zig").Unit) IRUnit {
    // v0: linear unit, single return
    for (u.body) |stmt| {
        switch (stmt.kind) {
            .Return => |v| {
                return IRUnit{ .return_value = v };
            },
            .VarDecl => {
                // Variable declarations are handled during codegen
                // For now, we just skip them in IR lowering
                continue;
            },
        }
    }

    // Default return 0 if no statements
    return IRUnit{ .return_value = 0 };
}
