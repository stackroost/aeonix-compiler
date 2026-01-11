const std = @import("std");

const llvm = @import("../../llvm.zig").c;

pub const TcKind = enum {
    Classifier,
    Action,
    TcxIngress,
    TcxEgress,
};

pub fn supports(section: []const u8) bool {
    return resolveTcKind(section) != null;
}

pub fn beginProgram(ctx: anytype, section: []const u8, name: []const u8) !void {
    const kind = resolveTcKind(section) orelse return @TypeOf(ctx.*).Error.UnsupportedSection;
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

fn resolveTcKind(section: []const u8) ?TcKind {
    // exact
    if (std.mem.eql(u8, section, "tc") or std.mem.eql(u8, section, "classifier"))
        return .Classifier;

    if (std.mem.eql(u8, section, "action"))
        return .Action;

    if (std.mem.eql(u8, section, "tcx/ingress") or std.mem.eql(u8, section, "tc/ingress"))
        return .TcxIngress;

    if (std.mem.eql(u8, section, "tcx/egress") or std.mem.eql(u8, section, "tc/egress"))
        return .TcxEgress;

    // patterns
    if (std.mem.startsWith(u8, section, "tc/")) {
        const extras = section["tc/".len..];
        if (isValidTcExtras(extras)) return .Classifier;
        return null;
    }
    if (std.mem.startsWith(u8, section, "classifier/")) {
        const extras = section["classifier/".len..];
        if (isValidTcExtras(extras)) return .Classifier;
        return null;
    }
    if (std.mem.startsWith(u8, section, "action/")) {
        const extras = section["action/".len..];
        if (isValidTcExtras(extras)) return .Action;
        return null;
    }

    return null;
}

fn isValidTcExtras(extras: []const u8) bool {
    if (extras.len == 0) return false;

    // common
    if (std.mem.eql(u8, extras, "ingress") or std.mem.eql(u8, extras, "egress")) return true;

    // conservative token set: [A-Za-z0-9._-]+
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
