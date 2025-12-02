const std = @import("std");
// small helpers - expand later
pub fn slurp(path: []const u8) ![]u8 {
    var file = try std.fs.cwd().openFile(path, .{ .read = true });
    defer file.close();
    const size = try file.getEndPos();
    var buf = try std.heap.page_allocator.alloc(u8, @intCast(usize, size));
    defer std.heap.page_allocator.free(buf);
    _ = try file.reader().readAll(buf);
    return buf;
}
