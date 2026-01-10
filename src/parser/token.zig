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
    keyword_map,
    keyword_type,
    keyword_key,
    keyword_value,
    keyword_max,

    // map types
    map_type_hash,
    map_type_array,
    map_type_ringbuf,
    map_type_lru_hash,
    map_type_prog_array,

    // type keywords
    type_u32,
    type_u64,
    type_i32,
    type_i64,

    // punctuation
    l_brace,
    r_brace,
    equals,
    colon,
    dot,

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
