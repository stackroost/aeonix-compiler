const std = @import("std");

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
        try writer.beginProgram(sec, name);
        try writer.emitLoadImm(0, unit_ir.return_value);
        writer.emitExit();
    }
}

fn sanitizeSectionForSymbol(writer: *ElfWriter, sec: []const u8) []const u8 {

    var buf = writer.arena.allocator().alloc(u8, sec.len) catch return "sec";
    for (sec, 0..) |ch, i| {
        buf[i] = switch (ch) {
            '/', '-', '.', ' ' => '_',
            else => ch,
        };
    }
    return buf;
}
