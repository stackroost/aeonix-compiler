const std = @import("std");
const Parser = @import("parser.zig").Parser;
const ast = @import("../ast/unit.zig");
const TokenKind = @import("token.zig").TokenKind;

pub const ParseError = error{
    MultipleUnits,
    UnexpectedToken,
    ParseError,
    UnterminatedComment,
    InvalidCharacter,
    ExpectedStringLiteral,
    UnterminatedString,
    InvalidEscapeSequence,
    OutOfMemory,
};

pub fn parse(src: []const u8, allocator: std.mem.Allocator) ParseError!ast.Unit {
    var p = try Parser.init(src, allocator);
    defer p.deinit();

    const unit = try p.parseUnit();
    
    // Ensure exactly one unit per file - check that we've reached EOF
    if (p.current.kind != .eof) {
        return error.MultipleUnits;
    }

    return unit;
}
