const std = @import("std");

const llvm = @cImport({
    @cInclude("llvm-c/Core.h");
    @cInclude("llvm-c/Target.h");
    @cInclude("llvm-c/TargetMachine.h");
    @cInclude("llvm-c/BitWriter.h");
});

pub const LLVMElfWriter = struct {
    allocator: std.mem.Allocator,

    context: llvm.LLVMContextRef,
    module: llvm.LLVMModuleRef,
    builder: llvm.LLVMBuilderRef,
    function: ?llvm.LLVMValueRef = null,

    license: []const u8 = "GPL",
    function_name: []const u8 = "main",

    pub fn init(allocator: std.mem.Allocator) !LLVMElfWriter {
        llvm.LLVMInitializeBPFTarget();
        llvm.LLVMInitializeBPFTargetInfo();
        llvm.LLVMInitializeBPFTargetMC();
        llvm.LLVMInitializeBPFAsmPrinter();

        const context = llvm.LLVMContextCreate();
        const module = llvm.LLVMModuleCreateWithNameInContext("bpf_module", context);
        const builder = llvm.LLVMCreateBuilderInContext(context);

        return .{
            .allocator = allocator,
            .context = context,
            .module = module,
            .builder = builder,
        };
    }

    pub fn deinit(self: *LLVMElfWriter) void {
        llvm.LLVMDisposeBuilder(self.builder);
        llvm.LLVMDisposeModule(self.module);
        llvm.LLVMContextDispose(self.context);
    }

    pub fn emitLicense(self: *LLVMElfWriter, license: []const u8) void {
        self.license = license;
    }

    pub fn beginProgram(self: *LLVMElfWriter, section: []const u8, name: []const u8) void {
        _ = section;
        self.function_name = name;

        const i64_ty = llvm.LLVMInt64TypeInContext(self.context);
        const fn_type = llvm.LLVMFunctionType(i64_ty, null, 0, 0);

        const fn_val = llvm.LLVMAddFunction(self.module, @as([*c]const u8, @ptrCast(self.function_name.ptr)), fn_type);
        self.function = fn_val;

        const entry = llvm.LLVMAppendBasicBlockInContext(self.context, fn_val, "entry");
        llvm.LLVMPositionBuilderAtEnd(self.builder, entry);
    }

    pub fn emitLoadImm(self: *LLVMElfWriter, reg: u8, val: i64) !void {
        if (reg != 0) return error.UnhandledRegister;

        const i64_ty = llvm.LLVMInt64TypeInContext(self.context);
        const imm = llvm.LLVMConstInt(
            i64_ty,
            @as(u64, @intCast(val)),
            0,
        );

        _ = llvm.LLVMBuildRet(self.builder, imm);
    }

    pub fn emitExit(self: *LLVMElfWriter) void {
        _ = self;
    }

    pub fn finish(self: *LLVMElfWriter) ![]u8 {
        var err: [*c]u8 = null;
        const triple = "bpf-pc-linux";

        var target: llvm.LLVMTargetRef = null;
        if (llvm.LLVMGetTargetFromTriple(triple, &target, @as([*c][*c]u8, @ptrCast(&err))) != 0) {
            return error.InvalidTarget;
        }

        const tm = llvm.LLVMCreateTargetMachine(
            target,
            triple,
            "generic",
            "",
            llvm.LLVMCodeGenLevelDefault,
            llvm.LLVMRelocStatic,
            llvm.LLVMCodeModelSmall,
        );

        const filename = "bpf_prog.o";
        if (llvm.LLVMTargetMachineEmitToFile(
            tm,
            self.module,
            filename,
            llvm.LLVMObjectFile,
            @as([*c][*c]u8, @ptrCast(&err)),
        ) != 0) {
            return error.ObjectEmitFailed;
        }

        const file = try std.fs.cwd().openFile(filename, .{});
        defer file.close();

        const size = try file.getEndPos();
        const buffer = try self.allocator.alloc(u8, size);

        _ = try file.readAll(buffer);
        return buffer;
    }
};
