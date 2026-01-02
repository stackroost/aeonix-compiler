const std = @import("std");

pub const TokenKind = enum {
    // keywords
    keyword_unit,
    keyword_section,
    keyword_license,
    keyword_return,

    // punctuation
    l_brace,
    r_brace,

    // literals
    identifier,
    string_literal,
    number,

    eof,
};

pub const Token = struct {
    kind: TokenKind,
    lexeme: []const u8,

    // optional numeric value (used by number tokens)
    int_value: i64 = 0,
};
