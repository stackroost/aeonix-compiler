const std = @import("std");
const llvm = @import("../../llvm.zig").c;

pub const CgroupKind = enum {
    Skb,     // "cgroup_skb", "cgroup_skb/ingress", "cgroup_skb/egress"
    Sock,    // "cgroup_sock"
    SockOps, // "sockops"
    SkMsg,   // "sk_msg"
};

pub fn supports(section: []const u8) bool {
    return resolveCgroupKind(section) != null;
}

pub fn beginProgram(ctx: anytype, section: []const u8, name: []const u8) !void {
    const kind = resolveCgroupKind(section) orelse return @TypeOf(ctx.*).Error.UnsupportedSection;

    const name_z = try ctx.dupeZ(name);
    const section_z = try ctx.dupeZ(section);

    const i32_ty = llvm.LLVMInt32TypeInContext(ctx.context);

    // Map the BPF program kind to the correct LLVM context struct name
    const ctx_struct_name = switch (kind) {
        .Skb => "struct __sk_buff",
        .Sock => "struct bpf_sock",
        .SockOps => "struct bpf_sock_ops",
        .SkMsg => "struct sk_msg_md",
    };

    // Create a named opaque struct and a pointer to it for the first argument
    const ctx_name_z = try ctx.dupeZ(ctx_struct_name);
    const opaque_struct = llvm.LLVMStructCreateNamed(ctx.context, ctx_name_z.ptr);
    const ctx_ptr_ty = llvm.LLVMPointerType(opaque_struct, 0);

    var params = [_]llvm.LLVMTypeRef{ctx_ptr_ty};
    const fn_type = llvm.LLVMFunctionType(i32_ty, &params, 1, 0);

    const fn_val = llvm.LLVMAddFunction(ctx.module, name_z.ptr, fn_type);
    llvm.LLVMSetSection(fn_val, section_z.ptr);

    ctx.function = fn_val;

    const entry = llvm.LLVMAppendBasicBlockInContext(ctx.context, fn_val, "entry");
    llvm.LLVMPositionBuilderAtEnd(ctx.builder, entry);
}

fn resolveCgroupKind(section: []const u8) ?CgroupKind {
    if (std.mem.startsWith(u8, section, "cgroup_skb")) {
        return .Skb;
    }
    if (std.mem.eql(u8, section, "cgroup_sock")) {
        return .Sock;
    }
    if (std.mem.eql(u8, section, "sockops")) {
        return .SockOps;
    }
    if (std.mem.eql(u8, section, "sk_msg")) {
        return .SkMsg;
    }
    return null;
}