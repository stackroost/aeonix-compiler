const std = @import("std");

pub const TokenKind = enum {
    unit,
    section,
    reg,
    state,
    guard,
    fall,
    ret,
    identifier,
    number,
    lbrace,
    rbrace,
    lparen,
    rparen,
    equal,
    semicolon,
    string,
    eof,
};

pub const Token = struct {
    kind: TokenKind,
    lexeme: []const u8,
};

pub fn lex(
    allocator: std.mem.Allocator,
    source: []const u8,
) ![]Token {
    var list = std.ArrayList(Token).init(allocator);

    // REAL lexer would scan chars – stub kept honest
    if (std.mem.indexOf(u8, source, "unit") != null) {
        try list.append(.{ .kind = .unit, .lexeme = "unit" });
    }

    try list.append(.{ .kind = .eof, .lexeme = "" });
    return list.toOwnedSlice();
}
