const std = @import("std");
pub fn fail(msg: []const u8) noreturn {
    _ = std.io.getStdErr().writer().writeAll(msg);
    @panic("failed");
}
