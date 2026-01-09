const std = @import("std");

pub const SourceLoc = struct {
    line: usize,
    column: usize,
    offset: usize,

    pub fn init(line: usize, column: usize, offset: usize) SourceLoc {
        return .{
            .line = line,
            .column = column,
            .offset = offset,
        };
    }
};

pub const TokenKind = enum {
    // keywords
    keyword_unit,
    keyword_section,
    keyword_license,
    keyword_return,
    keyword_reg,
    keyword_imm,

    // punctuation
    l_brace,
    r_brace,
    equals,

    // literals
    identifier,
    string_literal,
    number,

    eof,
};

pub const Token = struct {
    kind: TokenKind,
    lexeme: []const u8,
    loc: SourceLoc,

    // optional numeric value (used by number tokens)
    int_value: i64 = 0,
};
