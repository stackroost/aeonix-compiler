const std = @import("std");

const llvm = @import("../../llvm.zig").c;

pub const XdpKind = enum {
    Xdp,        // "xdp"
    Ingress,    // "xdp/ingress"
    Egress,     // "xdp/egress"
    Frags,      // "xdp/frags"
    Devmap,     // "xdp/devmap"
    Cpumap,     // "xdp/cpumap"
    Offload,    // "xdp/offload"
};

pub fn supports(section: []const u8) bool {
    return resolveXdpKind(section) != null;
}

pub fn beginProgram(ctx: anytype, section: []const u8, name: []const u8) !void {
    const kind = resolveXdpKind(section) orelse return @TypeOf(ctx.*).Error.UnsupportedSection;
    _ = kind;

    const name_z = try ctx.dupeZ(name);
    const section_z = try ctx.dupeZ(section);
    
    const i32_ty = llvm.LLVMInt32TypeInContext(ctx.context);
    const i8_ty = llvm.LLVMInt8TypeInContext(ctx.context);
    const ctx_ptr_ty = llvm.LLVMPointerType(i8_ty, 0);

    var params = [_]llvm.LLVMTypeRef{ ctx_ptr_ty };
    const fn_type = llvm.LLVMFunctionType(i32_ty, &params, 1, 0);

    const fn_val = llvm.LLVMAddFunction(ctx.module, name_z.ptr, fn_type);
    llvm.LLVMSetSection(fn_val, section_z.ptr);

    ctx.function = fn_val;

    const entry = llvm.LLVMAppendBasicBlockInContext(ctx.context, fn_val, "entry");
    llvm.LLVMPositionBuilderAtEnd(ctx.builder, entry);
}

fn resolveXdpKind(section: []const u8) ?XdpKind {
    // exact
    if (std.mem.eql(u8, section, "xdp"))
        return .Xdp;

    if (std.mem.eql(u8, section, "xdp/ingress"))
        return .Ingress;

    if (std.mem.eql(u8, section, "xdp/egress"))
        return .Egress;

    if (std.mem.eql(u8, section, "xdp/frags"))
        return .Frags;

    if (std.mem.eql(u8, section, "xdp/devmap"))
        return .Devmap;

    if (std.mem.eql(u8, section, "xdp/cpumap"))
        return .Cpumap;

    if (std.mem.eql(u8, section, "xdp/offload"))
        return .Offload;
        
    if (std.mem.startsWith(u8, section, "xdp/")) {
        const extras = section["xdp/".len..];
        
        if (std.mem.eql(u8, extras, "ingress")) return .Ingress;
        if (std.mem.eql(u8, extras, "egress")) return .Egress;
        if (std.mem.eql(u8, extras, "frags")) return .Frags;
        if (std.mem.eql(u8, extras, "devmap")) return .Devmap;
        if (std.mem.eql(u8, extras, "cpumap")) return .Cpumap;
        if (std.mem.eql(u8, extras, "offload")) return .Offload;
        
        if (isValidXdpExtras(extras)) return .Xdp;

        return null;
    }

    return null;
}

fn isValidXdpExtras(extras: []const u8) bool {
    if (extras.len == 0) return false;

    // conservative token set: [A-Za-z0-9._-]+ (same as tc.zig)
    for (extras) |ch| {
        const ok =
            (ch >= 'a' and ch <= 'z') or
            (ch >= 'A' and ch <= 'Z') or
            (ch >= '0' and ch <= '9') or
            ch == '_' or ch == '.' or ch == '-';
        if (!ok) return false;
    }
    return true;
}
