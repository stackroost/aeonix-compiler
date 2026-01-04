const std = @import("std");

const parser = @import("parser/mod.zig");
const sema = @import("sema/mod.zig");
const ir = @import("ir/unit.zig");
const codegen = @import("codegen/ebpf/unit.zig");
const ElfWriter = @import("elf/writer.zig").ElfWriter;
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
    if (src.len == 0) {
        return CompileError.EmptyInput;
    }

    var diagnostics = Diagnostics.init(allocator);
    defer diagnostics.deinit();

    // Parse
    var unit = try parser.parse(src, allocator);

    // Semantic analysis
    sema.checkUnit(&unit, &diagnostics, src) catch {
        diagnostics.printAllStd() catch {};
        return CompileError.CompilationFailed;
    };

    if (diagnostics.hasErrors()) {
        diagnostics.printAllStd() catch {};
        return CompileError.CompilationFailed;
    }

    // Lower to IR
    const unit_ir = ir.lowerUnit(&unit);

    // Codegen
    var elf_writer = try ElfWriter.init(allocator);
    defer elf_writer.deinit();

    try codegen.emitUnit(
        &elf_writer,
        unit_ir,
        unit.name,
        unit.sections,
        unit.license,
    );

    const elf_bytes = try elf_writer.finish();
    defer allocator.free(elf_bytes);

    try std.fs.cwd().writeFile(.{
        .sub_path = output_path,
        .data = elf_bytes,
    });
}
