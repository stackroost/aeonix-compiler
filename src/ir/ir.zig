const ast = @import("../ast/ast.zig");

pub const IRProgram = struct {
    units: []IRUnit,
};

pub const IRUnit = struct {
    instructions: []IRInst,
};

pub const IRInst = union(enum) {
    LoadImm: i64,
    Return,
};

pub fn lower(
    allocator: anytype,
    program: ast.Program,
) !IRProgram {
    _ = allocator;
    _ = program;
    return IRProgram{ .units = &[_]IRUnit{} };
}
