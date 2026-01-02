const std = @import("std");
const Token = @import("../parser/token.zig").Token;
const TokenKind = @import("../parser/token.zig").TokenKind;

pub const Lexer = struct {
    src: []const u8,
    index: usize = 0,

    pub fn init(src: []const u8) Lexer {
        return .{
            .src = src,
            .index = 0,
        };
    }

    pub fn next(self: *Lexer) !Token {
        _ = self;

        // TEMP stub lexer
        // Always return EOF for now
        return Token{
            .kind = .eof,
            .lexeme = "",
        };
    }
};
