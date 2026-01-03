const std = @import("std");

const parser = @import("parser/mod.zig");
const sema = @import("sema/mod.zig");
const ir = @import("ir/unit.zig");
const codegen = @import("./codegen/ebpf/unit.zig");
const ElfWriter = @import("elf/writer.zig").ElfWriter;
const Diagnostics = @import("diagnostics.zig").Diagnostics;

pub fn compile(src: []const u8, output_path: []const u8) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Validate input
    if (src.len == 0) {
        std.log.err("Error: Input file is empty", .{});
        return error.EmptyInput;
    }

    // Parse
    var diagnostics = Diagnostics.init(allocator);
    defer diagnostics.deinit();

    var unit = parser.parse(src, allocator) catch |err| {
        std.log.err("Parse error: {any}", .{err});
        return err;
    };

    // Semantic analysis
    sema.checkUnit(&unit, &diagnostics, src) catch |err| {
        diagnostics.printAllStd() catch {};
        return err;
    };

    // Print warnings
    if (diagnostics.diagnostics.items.len > 0) {
        diagnostics.printAllStd() catch {};
    }

    if (diagnostics.hasErrors()) {
        return error.CompilationFailed;
    }

    // Lower to IR
    const unit_ir = ir.lowerUnit(&unit);

    // Code generation
    var elf_writer = try ElfWriter.init(allocator);
    defer elf_writer.deinit();

    try codegen.emitUnit(
        &elf_writer,
        unit_ir,
        unit.sections,
        unit.license,
    );

    const elf_bytes = try elf_writer.finish();
    defer allocator.free(elf_bytes);
    try std.fs.cwd().writeFile(.{ .sub_path = output_path, .data = elf_bytes });
}
