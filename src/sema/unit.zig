const std = @import("std");
const ast = @import("../ast/unit.zig");
const Diagnostics = @import("../diagnostics.zig");

pub fn checkUnit(u: *ast.Unit, diag: *Diagnostics) bool {
    // section required
    if (u.sections.len == 0) {
        diag.error("unit must declare at least one section");
        return false;
    }

    // license default
    if (u.license == null) {
        u.license = "GPL";
    }

    // exactly one return
    var returns: usize = 0;
    for (u.body) |stmt| {
        switch (stmt) {
            .Return => returns += 1,
        }
    }

    if (returns != 1) {
        diag.error("unit must have exactly one return");
        return false;
    }

    return true;
}
