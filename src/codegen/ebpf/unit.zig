const ir = @import("../../ir/unit.zig");
const ElfWriter = @import("../../elf/writer.zig").LLVMElfWriter;

pub fn emitUnit(
    writer: *ElfWriter,
    unit_ir: ir.IRUnit,
    name: []const u8,
    sections: []const []const u8,
    license: ?[]const u8,
) !void {
    if (license) |lic| writer.emitLicense(lic);

    for (sections) |sec| {
        writer.beginProgram(sec, name);
        try writer.emitLoadImm(0, unit_ir.return_value);
        writer.emitExit();
    }
}
