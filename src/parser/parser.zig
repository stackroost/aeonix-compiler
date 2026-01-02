const std = @import("std");
const Token = @import("token.zig").Token;
const TokenKind = @import("token.zig").TokenKind;
const Lexer = @import("../lexer/lexer.zig").Lexer;
const ast = @import("../ast/unit.zig");

pub const Parser = struct {
    allocator: std.mem.Allocator,
    lexer: Lexer,
    current: Token,

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

    pub fn advance(self: *Parser) !void {
        self.current = try self.lexer.next();
    }

    pub fn match(self: *Parser, kind: TokenKind) bool {
        if (self.current.kind == kind) {
            _ = self.advance() catch {};
            return true;
        }
        return false;
    }

    pub fn expect(self: *Parser, kind: TokenKind) !Token {
        if (self.current.kind != kind) {
            return error.UnexpectedToken;
        }
        const tok = self.current;
        try self.advance();
        return tok;
    }

    pub fn parseError(self: *Parser, msg: []const u8) !noreturn {
        _ = self;
        _ = msg;
        return error.ParseError;
    }

    pub fn parseUnit(self: *Parser) !ast.Unit {
        // Stub implementation
        const name = try self.allocator.dupe(u8, "");
        const sections = try self.allocator.alloc([]const u8, 0);
        const body = try self.allocator.alloc(ast.Stmt, 0);

        return ast.Unit{
            .name = name,
            .sections = sections,
            .license = null,
            .body = body,
        };
    }
};
