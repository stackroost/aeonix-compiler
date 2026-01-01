const std = @import("std");
const codegen = @import("../ebpf/codegen.zig");

pub fn writeObject(path: []const u8, obj: *codegen.Obj) !void {
    _ = obj;

    var f = try std.fs.cwd().createFile(path, .{ .truncate = true });
    defer f.close();

    // Stage-0 placeholder: empty file is already created+truncated.
}
