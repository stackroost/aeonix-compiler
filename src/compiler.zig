const std = @import("std");

const parser = @import("parser/mod.zig");
const sema = @import("sema/mod.zig");
const ir = @import("ir/unit.zig");
const codegen = @import("./codegen/ebpf/unit.zig");
const ElfWriter = @import("elf/writer.zig").ElfWriter;

pub fn compile(src: []const u8) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var unit = try parser.parse(src, allocator);

    if (!sema.checkUnit(&unit)) return;

    const unit_ir = ir.lowerUnit(&unit);

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
    try std.fs.cwd().writeFile(.{ .sub_path = "out.o", .data = elf_bytes });
}
