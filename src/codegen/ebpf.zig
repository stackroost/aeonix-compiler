const ir = @import("../ir/ir.zig");

pub const EbpfProgram = struct {
    bytes: []u8,
};

pub fn generate(
    allocator: anytype,
    program: ir.IRProgram,
) !EbpfProgram {
    _ = program;
    return .{ .bytes = try allocator.alloc(u8, 8) };
}
