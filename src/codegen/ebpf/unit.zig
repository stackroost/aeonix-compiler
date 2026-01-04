const ir = @import("../../ir/unit.zig");
const ElfWriter = @import("../../elf/writer.zig").ElfWriter;

pub fn emitUnit(
    writer: *ElfWriter,
    unit_ir: ir.IRUnit,
    name: []const u8,
    sections: []const []const u8,
    license: ?[]const u8,
) !void {
    try writer.emitLicense(license);

    for (sections) |sec| {
        try writer.beginProgram(sec, name);

        // load return value into R0
        try writer.emitLoadImm(0, unit_ir.return_value);

        // exit
        try writer.emitExit();
    }
}
