const std = @import("std");
const Parser = @import("parser.zig").Parser;
const ast = @import("../ast/mod.zig");
const TokenKind = @import("token.zig").TokenKind;

pub const ParseError = error{
    UnexpectedToken,
    ParseError,
    UnterminatedComment,
    InvalidCharacter,
    ExpectedStringLiteral,
    UnterminatedString,
    InvalidEscapeSequence,
    OutOfMemory,
};

pub fn parse(src: []const u8, allocator: std.mem.Allocator) !ast.Program {
    var p = try Parser.init(src, allocator);
    defer p.deinit();
    return p.parseProgram();
}
