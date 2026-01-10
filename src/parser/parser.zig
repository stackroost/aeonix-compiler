const std = @import("std");
const Token = @import("token.zig").Token;
const TokenKind = @import("token.zig").TokenKind;
const Lexer = @import("../lexer/lexer.zig").Lexer;
const ast = @import("../ast/unit.zig");

pub const Parser = struct {
    allocator: std.mem.Allocator,
    lexer: Lexer,
    current: Token,

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

    pub fn init(src: []const u8, allocator: std.mem.Allocator) !Parser {
        var lexer = Lexer.init(src);
        const first = try lexer.next();

        return Parser{
            .allocator = allocator,
            .lexer = lexer,
            .current = first,
        };
    }

    pub fn deinit(self: *Parser) void {
        _ = self;
    }

    pub fn advance(self: *Parser) ParseError!void {
        self.current = try self.lexer.next();
    }

    pub fn match(self: *Parser, kind: TokenKind) bool {
        if (self.current.kind == kind) {
            _ = self.advance() catch {}; // swallow error here as you already do
            return true;
        }
        return false;
    }

    pub fn expect(self: *Parser, kind: TokenKind) ParseError!Token {
        if (self.current.kind != kind) {
            return error.UnexpectedToken;
        }
        const tok = self.current;
        try self.advance();
        return tok;
    }

    pub fn parseError(self: *Parser, msg: []const u8) ParseError {
        _ = self;
        _ = msg;
        // (optional) record msg somewhere / print it, etc.
        return error.ParseError;
    }

    pub fn parseUnit(self: *Parser) ParseError!ast.Unit {
        const unit_parser = @import("unit.zig");
        return unit_parser.parseUnit(self);
    }

    pub fn parseExpr(self: *Parser) ParseError!*ast.Expr {
        const unit_parser = @import("unit.zig");
        return unit_parser.parseExpr(self);
    }
};
