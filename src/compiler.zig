const std = @import("std");

const parser = @import("parser/mod.zig");
const sema = @import("sema/mod.zig");
const ir = @import("ir/mod.zig");
const codegen = @import("codegen/ebpf/unit.zig");
const ElfWriter = @import("elf/writer.zig").LLVMElfWriter;
const Diagnostics = @import("diagnostics.zig").Diagnostics;

pub const CompileError = error{
    EmptyInput,
    CompilationFailed,
};

pub fn compile(
    allocator: std.mem.Allocator,
    src: []const u8,
    output_path: []const u8,
) !void {
    if (src.len == 0) return CompileError.EmptyInput;

    var diagnostics = Diagnostics.init(allocator);
    defer diagnostics.deinit();

    const program = parser.parse(src, allocator) catch {
        const SourceLoc = @import("parser/token.zig").SourceLoc;
        try diagnostics.reportError("Parse error", SourceLoc.init(1, 1, 0), src);
        diagnostics.printAllStd() catch {};
        return CompileError.CompilationFailed;
    };

    sema.checkProgram(&program, &diagnostics, src) catch {
        diagnostics.printAllStd() catch {};
        return CompileError.CompilationFailed;
    };

    if (diagnostics.hasErrors()) {
        diagnostics.printAllStd() catch {};
        return CompileError.CompilationFailed;
    }

    const program_ir = ir.lowerProgram(&program, allocator) catch {
        std.debug.print("IR lower failed\n", .{});
        return CompileError.CompilationFailed;
    };

    var elf_writer = try ElfWriter.init(allocator);
    defer elf_writer.deinit();

    // Global maps
    for (program.maps) |map_decl| {
        try elf_writer.emitMapDefinition(map_decl);
    }

    // All eBPF programs
    for (program_ir.units) |unit_ir| {
        try codegen.emitUnit(
            &elf_writer,
            unit_ir,
            unit_ir.name,
            unit_ir.sections,
            unit_ir.license,
        );
    }

    const elf_bytes = try elf_writer.finish();
    defer allocator.free(elf_bytes);

    try std.fs.cwd().writeFile(.{
        .sub_path = output_path,
        .data = elf_bytes,
    });
}
