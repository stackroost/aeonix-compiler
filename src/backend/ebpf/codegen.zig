const std = @import("std");
const ir_mod = @import("../../middle/ir.zig");

pub const Obj = struct {
    pub fn deinit(self: *Obj, alloc: std.mem.Allocator) void {
        _ = self; _ = alloc;
    }
};

pub fn generate(alloc: std.mem.Allocator, ir: *ir_mod.IR) !Obj {
    _ = alloc; _ = ir;
    return Obj{};
}
