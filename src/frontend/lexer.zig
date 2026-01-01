const std = @import("std");

pub const Token = struct {
    kind: Kind,
    start: u32,
    end: u32,
    pub const Kind = enum { ident, number, string, keyword, symbol, eof };
};

pub const TokenList = std.ArrayList(Token);

pub fn tokenize(alloc: std.mem.Allocator, src: []const u8) !TokenList {
    // Stage-0 placeholder lexer: returns only EOF

    var list = try TokenList.initCapacity(alloc, 1);
    errdefer list.deinit(alloc);

    try list.append(alloc, .{
        .kind = .eof,
        .start = 0,
        .end = @intCast(src.len),
    });

    return list;
}
