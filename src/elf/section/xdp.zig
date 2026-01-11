const std = @import("std");

pub fn supports(section: []const u8) bool {
    return std.mem.eql(u8, section, "xdp") or std.mem.eql(u8, section, "xdp/ingress");
}

pub fn beginProgram(ctx: anytype, section: []const u8, name: []const u8) !void {
    _ = section;
    _ = name;
    return @TypeOf(ctx.*).Error.NotImplemented;
}