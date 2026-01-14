const std = @import("std");

const tc = @import("./section/tc.zig");
const xdp = @import("./section/xdp.zig");
const tp = @import("./section/tracepoint.zig");
const cgroup = @import("./section/cgroup.zig");

const llvm = @import("../llvm.zig").c;

pub const LLVMElfWriter = struct {
    pub const Error = error{
        InvalidTarget,
        ObjectEmitFailed,
        UnsupportedSection,
        UnhandledRegister,
        NotImplemented,
    };

    allocator: std.mem.Allocator,
    arena: std.heap.ArenaAllocator,

    context: llvm.LLVMContextRef,
    module: llvm.LLVMModuleRef,
    builder: llvm.LLVMBuilderRef,

    function: ?llvm.LLVMValueRef = null,

    license: []const u8 = "GPL",

    pub fn init(allocator: std.mem.Allocator) !LLVMElfWriter {
        llvm.LLVMInitializeBPFTarget();
        llvm.LLVMInitializeBPFTargetInfo();
        llvm.LLVMInitializeBPFTargetMC();
        llvm.LLVMInitializeBPFAsmPrinter();

        var arena = std.heap.ArenaAllocator.init(allocator);
        errdefer arena.deinit();

        const context = llvm.LLVMContextCreate();
        errdefer llvm.LLVMContextDispose(context);

        const module = llvm.LLVMModuleCreateWithNameInContext("bpf_module", context);
        errdefer llvm.LLVMDisposeModule(module);

        const builder = llvm.LLVMCreateBuilderInContext(context);
        errdefer llvm.LLVMDisposeBuilder(builder);

        return .{
            .allocator = allocator,
            .arena = arena,
            .context = context,
            .module = module,
            .builder = builder,
        };
    }

    pub fn deinit(self: *LLVMElfWriter) void {
        llvm.LLVMDisposeBuilder(self.builder);
        llvm.LLVMDisposeModule(self.module);
        llvm.LLVMContextDispose(self.context);
        self.arena.deinit();
    }

    pub fn dupeZ(self: *LLVMElfWriter, s: []const u8) ![:0]const u8 {
        return self.arena.allocator().dupeZ(u8, s);
    }

    pub fn emitLicense(self: *LLVMElfWriter, license: []const u8) void {
        self.license = license;
    }

    pub fn isSectionSupported(_: *LLVMElfWriter, section: []const u8) bool {
        return tc.supports(section) or
            xdp.supports(section) or
            tp.supports(section) or
            cgroup.supports(section);
    }

    pub fn beginProgram(self: *LLVMElfWriter, section: []const u8, name: []const u8) !void {
        self.function = null;

        if (tc.supports(section)) {
            return tc.beginProgram(self, section, name);
        } else if (xdp.supports(section)) {
            return xdp.beginProgram(self, section, name);
        } else if (tp.supports(section)) {
            return tp.beginProgram(self, section, name);
        } else if (cgroup.supports(section)) { // Add this
            return cgroup.beginProgram(self, section, name);
        }

        return Error.UnsupportedSection;
    }

    pub fn emitLoadImm(self: *LLVMElfWriter, reg: u8, val: i64) !void {
        if (reg != 0) return Error.UnhandledRegister;
        if (self.function == null) return Error.ObjectEmitFailed;

        const i32_ty = llvm.LLVMInt32TypeInContext(self.context);

        const bits64: u64 = @bitCast(val);
        const bits32: u32 = @truncate(bits64);

        const imm = llvm.LLVMConstInt(i32_ty, @as(u64, bits32), 0);
        _ = llvm.LLVMBuildRet(self.builder, imm);
    }

    pub fn emitExit(self: *LLVMElfWriter) void {
        _ = self;
    }

    pub fn finish(self: *LLVMElfWriter) ![]u8 {
        try self.ensureLicenseSection();

        var err_msg: [*c]u8 = null;
        const triple = "bpf-pc-linux";

        var target: llvm.LLVMTargetRef = null;
        if (llvm.LLVMGetTargetFromTriple(triple, &target, @as([*c][*c]u8, @ptrCast(&err_msg))) != 0) {
            if (err_msg != null) llvm.LLVMDisposeMessage(err_msg);
            return Error.InvalidTarget;
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
        if (tm == null) return Error.ObjectEmitFailed;
        defer llvm.LLVMDisposeTargetMachine(tm);

        llvm.LLVMSetTarget(self.module, triple);

        const td = llvm.LLVMCreateTargetDataLayout(tm);
        defer llvm.LLVMDisposeTargetData(td);

        const dl_str = llvm.LLVMCopyStringRepOfTargetData(td);
        defer llvm.LLVMDisposeMessage(dl_str);

        llvm.LLVMSetDataLayout(self.module, dl_str);

        const filename = "bpf_prog.o";
        if (llvm.LLVMTargetMachineEmitToFile(
            tm,
            self.module,
            filename,
            llvm.LLVMObjectFile,
            @as([*c][*c]u8, @ptrCast(&err_msg)),
        ) != 0) {
            if (err_msg != null) llvm.LLVMDisposeMessage(err_msg);
            return Error.ObjectEmitFailed;
        }
        if (err_msg != null) llvm.LLVMDisposeMessage(err_msg);

        // Read bytes
        const file = try std.fs.cwd().openFile(filename, .{});
        defer file.close();

        const size = try file.getEndPos();
        const buffer = try self.allocator.alloc(u8, size);
        errdefer self.allocator.free(buffer);

        _ = try file.readAll(buffer);
        return buffer;
    }

    fn ensureLicenseSection(self: *LLVMElfWriter) !void {
        const section_name_z = try self.dupeZ("license");
        const global_name_z = try self.dupeZ("__license");

        const lic_bytes = self.license;
        const lic_const = llvm.LLVMConstStringInContext(
            self.context,
            lic_bytes.ptr,
            @as(c_uint, @intCast(lic_bytes.len)),
            0,
        );

        const lic_ty = llvm.LLVMTypeOf(lic_const);
        const glob = llvm.LLVMAddGlobal(self.module, lic_ty, global_name_z.ptr);

        // Use internal linkage (static) and a private symbol name to avoid
        // changing the symbol binding to STB_GLOBAL when emitting the object.
        llvm.LLVMSetLinkage(glob, llvm.LLVMInternalLinkage);
        llvm.LLVMSetSection(glob, section_name_z.ptr);
        llvm.LLVMSetInitializer(glob, lic_const);
        llvm.LLVMSetGlobalConstant(glob, 1);
        llvm.LLVMSetAlignment(glob, 1);
    }
};
