const std = @import("std");
const llvm = @import("../../llvm.zig").c;

pub const TracepointKind = enum {
    Standard,     
    Raw,          
    Btf,          
};

pub fn supports(section: []const u8) bool {
    return resolveTracepointKind(section) != null;
}

pub fn beginProgram(ctx: anytype, section: []const u8, name: []const u8) !void {
    const kind = resolveTracepointKind(section) orelse return @TypeOf(ctx.*).Error.UnsupportedSection;

    const name_z = try ctx.dupeZ(name);
    const section_z = try ctx.dupeZ(section);

    const i32_ty = llvm.LLVMInt32TypeInContext(ctx.context);
    
    
    
    const context_ty = if (kind == .Raw) 
        llvm.LLVMInt64TypeInContext(ctx.context) 
    else 
        llvm.LLVMInt8TypeInContext(ctx.context);
        
    const ctx_ptr_ty = llvm.LLVMPointerType(context_ty, 0);

    var params = [_]llvm.LLVMTypeRef{ ctx_ptr_ty };
    const fn_type = llvm.LLVMFunctionType(i32_ty, &params, 1, 0);

    const fn_val = llvm.LLVMAddFunction(ctx.module, name_z.ptr, fn_type);
    llvm.LLVMSetSection(fn_val, section_z.ptr);

    ctx.function = fn_val;

    const entry = llvm.LLVMAppendBasicBlockInContext(ctx.context, fn_val, "entry");
    llvm.LLVMPositionBuilderAtEnd(ctx.builder, entry);
}

fn resolveTracepointKind(section: []const u8) ?TracepointKind {
    if (std.mem.startsWith(u8, section, "tracepoint/") or std.mem.startsWith(u8, section, "tp/")) {
        return .Standard;
    }
    if (std.mem.startsWith(u8, section, "raw_tracepoint/") or std.mem.startsWith(u8, section, "raw_tp/")) {
        return .Raw;
    }
    if (std.mem.startsWith(u8, section, "tp_btf/")) {
        return .Btf;
    }
    return null;
}