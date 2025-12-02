const std = @import("std");

fn a8(list: *std.ArrayList(u8), allocator: std.mem.Allocator, v: u8) void {
    _ = list.append(allocator, v) catch {};
}
fn a32(list: *std.ArrayList(u8), allocator: std.mem.Allocator, v: u32) void {
    _ = list.appendSlice(allocator, &[_]u8{ @intCast(v & 0xff), @intCast((v >> 8) & 0xff), @intCast((v >> 16) & 0xff), @intCast((v >> 24) & 0xff) }) catch {};
}
fn a64(list: *std.ArrayList(u8), allocator: std.mem.Allocator, v: u64) void {
    for (0..8) |ii| {
        const i = ii;
        _ = list.append(allocator, @intCast((v >> @intCast(i * 8)) & 0xff)) catch {};
    }
}

pub fn write_executable(msg: []const u8) !void {
    var out = try std.ArrayList(u8).initCapacity(std.heap.page_allocator, 0);
    defer out.deinit(std.heap.page_allocator);

    const base_vaddr: u64 = 0x400000;
    const entry_rva: u64 = 0x78;

    // ELF ident
    _ = out.appendSlice(std.heap.page_allocator, &[_]u8{ 0x7f, 'E', 'L', 'F', 2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0 }) catch {};
    a32(&out, std.heap.page_allocator, 1); // e_type+machine packed? (kept simple)
    a64(&out, std.heap.page_allocator, base_vaddr + entry_rva);
    a64(&out, std.heap.page_allocator, 0x40);
    a64(&out, std.heap.page_allocator, 0);
    a32(&out, std.heap.page_allocator, 0);
    a32(&out, std.heap.page_allocator, 64);
    a32(&out, std.heap.page_allocator, 56);
    a32(&out, std.heap.page_allocator, 1);

    // Program header
    a32(&out, std.heap.page_allocator, 1);
    a32(&out, std.heap.page_allocator, 5);
    a64(&out, std.heap.page_allocator, 0);
    a64(&out, std.heap.page_allocator, base_vaddr);
    a64(&out, std.heap.page_allocator, base_vaddr);
    // placeholder filesz/memsz
    const patch_pos = out.items.len;
    a64(&out, std.heap.page_allocator, 0);
    a64(&out, std.heap.page_allocator, 0);
    a64(&out, std.heap.page_allocator, 0x200000);

    // code: minimal write syscall + exit (same as earlier)
    _ = out.appendSlice(std.heap.page_allocator, &[_]u8{ 0x48, 0xC7, 0xC0, 0x01, 0, 0, 0, 0x48, 0xC7, 0xC7, 0x01, 0, 0, 0, 0x48, 0x8D, 0x35, 0x15, 0, 0, 0 }) catch {};
    const lenpos = out.items.len;
    _ = out.appendSlice(std.heap.page_allocator, &[_]u8{ 0x48, 0xC7, 0xC2, 0, 0, 0, 0, 0x0F, 0x05, 0x48, 0xC7, 0xC0, 0x3C, 0, 0, 0, 0x48, 0x31, 0xFF, 0x0F, 0x05 }) catch {};

    // append message
    _ = out.appendSlice(std.heap.page_allocator, msg) catch {};

    // patch len (imm32 at lenpos+3)
    const len32: u32 = @intCast(msg.len);
    out.items[lenpos + 3] = @intCast(len32 & 0xff);
    out.items[lenpos + 4] = @intCast((len32 >> 8) & 0xff);
    out.items[lenpos + 5] = @intCast((len32 >> 16) & 0xff);
    out.items[lenpos + 6] = @intCast((len32 >> 24) & 0xff);

    // patch filesz/memsz
    const total: u64 = @intCast(out.items.len);
    for (0..8) |ii| {
        const i = ii;
        out.items[patch_pos + i] = @intCast((total >> @intCast(i * 8)) & 0xff);
        out.items[patch_pos + 8 + i] = @intCast((total >> @intCast(i * 8)) & 0xff);
    }

    // write a.out
    var f = try std.fs.cwd().createFile("a.out", .{ .truncate = true, .mode = 0o755 });
    defer f.close();
    try f.writeAll(out.items);
    std.debug.print("wrote a.out ({}) bytes\n", .{out.items.len});
}
