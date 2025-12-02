const std = @import("std");

pub fn write_executable(msg: []const u8) !void {
    var out = std.ArrayList(u8).init(std.heap.page_allocator);
    defer out.deinit();

    const base_vaddr: u64 = 0x400000;
    const entry_rva: u64 = 0x78;

    // helper appends
    inline fn a8(list: *std.ArrayList(u8), v: u8) void { _ = list.append(v) catch {}; }
    inline fn a32(list: *std.ArrayList(u8), v: u32) void {
        _ = list.appendAll(&[_]u8{ @intCast(u8, v & 0xff), @intCast(u8, (v >> 8) & 0xff), @intCast(u8, (v >> 16) & 0xff), @intCast(u8, (v >> 24) & 0xff) }) catch {};
    }
    inline fn a64(list: *std.ArrayList(u8), v: u64) void {
        for (0..<8) |i| {
            _ = list.append(@intCast(u8, (v >> (i * 8)) & 0xff)) catch {};
        }
    }

    // ELF ident
    _ = out.appendAll(&[_]u8{0x7f, 'E', 'L', 'F', 2, 1, 1, 0, 0,0,0,0,0,0,0,0}) catch {};
    a32(&out, 1); // e_type+machine packed? (kept simple)
    a64(&out, base_vaddr + entry_rva);
    a64(&out, 0x40);
    a64(&out, 0);
    a32(&out, 0);
    a32(&out, 64);
    a32(&out, 56);
    a32(&out, 1);

    // Program header
    a32(&out, 1);
    a32(&out, 5);
    a64(&out, 0);
    a64(&out, base_vaddr);
    a64(&out, base_vaddr);
    // placeholder filesz/memsz
    const patch_pos = out.len;
    a64(&out, 0);
    a64(&out, 0);
    a64(&out, 0x200000);

    // code: minimal write syscall + exit (same as earlier)
    _ = out.appendAll(&[_]u8{0x48,0xC7,0xC0,0x01,0,0,0,  0x48,0xC7,0xC7,0x01,0,0,0,  0x48,0x8D,0x35,0x15,0,0,0}) catch {};
    const lenpos = out.len;
    _ = out.appendAll(&[_]u8{0x48,0xC7,0xC2,0,0,0,0,  0x0F,0x05,  0x48,0xC7,0xC0,0x3C,0,0,0,  0x48,0x31,0xFF,  0x0F,0x05}) catch {};

    // append message
    _ = out.appendAll(msg) catch {};

    // patch len (imm32 at lenpos+3)
    const len32: u32 = @intCast(u32, msg.len);
    out.items[lenpos + 3] = @intCast(u8, len32 & 0xff);
    out.items[lenpos + 4] = @intCast(u8, (len32 >> 8) & 0xff);
    out.items[lenpos + 5] = @intCast(u8, (len32 >> 16) & 0xff);
    out.items[lenpos + 6] = @intCast(u8, (len32 >> 24) & 0xff);

    // patch filesz/memsz
    const total: u64 = @intCast(u64, out.len);
    for (i, _) in std.range(0, 8) {
        out.items[patch_pos + i] = @intCast(u8, (total >> (i*8)) & 0xff);
        out.items[patch_pos + 8 + i] = @intCast(u8, (total >> (i*8)) & 0xff);
    }

    // write a.out
    var f = try std.fs.cwd().createFile("a.out", .{ .create = true, .truncate = true, .mode = 0o755 });
    defer f.close();
    try f.writeAll(out.items);
    try std.debug.print("wrote a.out ({}) bytes\n", .{out.len});
}
