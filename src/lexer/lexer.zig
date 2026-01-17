const std = @import("std");
const Token = @import("../parser/token.zig").Token;
const TokenKind = @import("../parser/token.zig").TokenKind;
const SourceLoc = @import("../parser/token.zig").SourceLoc;

pub const Lexer = struct {
    src: []const u8,
    index: usize = 0,
    line: usize = 1,
    column: usize = 1,

    pub fn init(src: []const u8) Lexer {
        return .{
            .src = src,
            .index = 0,
            .line = 1,
            .column = 1,
        };
    }

    fn currentLoc(self: *const Lexer) SourceLoc {
        return SourceLoc.init(self.line, self.column, self.index);
    }

    fn peek(self: *const Lexer) u8 {
        if (self.index >= self.src.len) return 0;
        return self.src[self.index];
    }

    fn advance(self: *Lexer) void {
        if (self.index < self.src.len) {
            if (self.src[self.index] == '\n') {
                self.line += 1;
                self.column = 1;
            } else {
                self.column += 1;
            }
            self.index += 1;
        }
    }

    fn skipWhitespace(self: *Lexer) void {
        while (self.index < self.src.len) {
            const ch = self.src[self.index];
            if (ch == ' ' or ch == '\t' or ch == '\r' or ch == '\n') {
                self.advance();
            } else break;
        }
    }

    fn skipComment(self: *Lexer) !void {
        if (self.peek() == '/') {
            self.advance();
            if (self.peek() == '/') {
                self.advance();
                while (self.index < self.src.len and self.src[self.index] != '\n') {
                    self.advance();
                }
                if (self.index < self.src.len) self.advance();
            } else if (self.peek() == '*') {
                self.advance();
                while (self.index < self.src.len) {
                    if (self.src[self.index] == '*' and self.index + 1 < self.src.len and self.src[self.index + 1] == '/') {
                        self.advance();
                        self.advance();
                        return;
                    }
                    self.advance();
                }
                return error.UnterminatedComment;
            } else {
                self.index -= 1; // not a comment, backtrack
                self.column -= 1;
            }
        }
    }

    fn readIdentifier(self: *Lexer) Token {
        const start = self.index;
        const loc = self.currentLoc();

        while (self.index < self.src.len) {
            const ch = self.peek();
            if ((ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z') or (ch >= '0' and ch <= '9') or ch == '_') {
                self.advance();
            } else break;
        }
        const lexeme = self.src[start..self.index];

        const kind: TokenKind =
            if (std.mem.eql(u8, lexeme, "unit")) .keyword_unit else if (std.mem.eql(u8, lexeme, "section")) .keyword_section else if (std.mem.eql(u8, lexeme, "license")) .keyword_license else if (std.mem.eql(u8, lexeme, "return")) .keyword_return else if (std.mem.eql(u8, lexeme, "reg")) .keyword_reg else if (std.mem.eql(u8, lexeme, "imm")) .keyword_imm else if (std.mem.eql(u8, lexeme, "map")) .keyword_map else if (std.mem.eql(u8, lexeme, "type")) .keyword_type else if (std.mem.eql(u8, lexeme, "key")) .keyword_key else if (std.mem.eql(u8, lexeme, "value")) .keyword_value else if (std.mem.eql(u8, lexeme, "max")) .keyword_max else if (std.mem.eql(u8, lexeme, "if")) .keyword_if else if (std.mem.eql(u8, lexeme, "guard")) .keyword_guard else if (std.mem.eql(u8, lexeme, "heap")) .keyword_heap else if (std.mem.eql(u8, lexeme, "u32")) .type_u32 else if (std.mem.eql(u8, lexeme, "u64")) .type_u64 else if (std.mem.eql(u8, lexeme, "i32")) .type_i32 else if (std.mem.eql(u8, lexeme, "i64")) .type_i64 else .identifier;

        return Token{ .kind = kind, .lexeme = lexeme, .loc = loc, .int_value = 0 };
    }

    fn readNumber(self: *Lexer) !Token {
        const start = self.index;
        const loc = self.currentLoc();
        var value: i64 = 0;
        var negative = false;

        if (self.peek() == '-') {
            negative = true;
            self.advance();
        }

        if (self.index + 1 < self.src.len and self.src[self.index] == '0' and self.src[self.index + 1] == 'x') {
            self.advance();
            self.advance();
            var has_digits = false;
            while (self.index < self.src.len) {
                const ch = self.peek();
                if (ch >= '0' and ch <= '9') {
                    value = value * 16 + @as(i64, ch - '0');
                    has_digits = true;
                    self.advance();
                } else if (ch >= 'a' and ch <= 'f') {
                    value = value * 16 + @as(i64, ch - 'a' + 10);
                    has_digits = true;
                    self.advance();
                } else if (ch >= 'A' and ch <= 'F') {
                    value = value * 16 + @as(i64, ch - 'A' + 10);
                    has_digits = true;
                    self.advance();
                } else break;
            }
            if (!has_digits) return error.InvalidCharacter;
        } else {
            while (self.index < self.src.len and self.peek() >= '0' and self.peek() <= '9') {
                value = value * 10 + @as(i64, self.peek() - '0');
                self.advance();
            }
        }

        if (negative) value = -value;
        const lexeme = self.src[start..self.index];
        return Token{ .kind = .number, .lexeme = lexeme, .loc = loc, .int_value = value };
    }

    fn readString(self: *Lexer) !Token {
        const start = self.index;
        const loc = self.currentLoc();
        if (self.peek() != '"') return error.ExpectedStringLiteral;
        self.advance();
        while (self.index < self.src.len) {
            const ch = self.peek();
            if (ch == '"') {
                self.advance();
                const lexeme = self.src[start..self.index];
                return Token{
                    .kind = .string_literal,
                    .lexeme = lexeme,
                    .loc = loc,
                    .int_value = 0,
                };
            } else if (ch == '\\') {
                self.advance();
                if (self.index >= self.src.len) {
                    return error.UnterminatedString;
                }
                const esc = self.peek();
                switch (esc) {
                    '"', '\\', 'n' => self.advance(),
                    else => return error.InvalidEscapeSequence,
                }
            } else if (ch == '\n') {
                return error.UnterminatedString;
            } else {
                self.advance();
            }
        }
        return error.UnterminatedString;
    }

    pub fn next(self: *Lexer) !Token {
        while (true) {
            self.skipWhitespace();
            if (self.index >= self.src.len) return Token{ .kind = .eof, .lexeme = "", .loc = self.currentLoc(), .int_value = 0 };
            const before = self.index;
            self.skipComment() catch {};
            if (self.index == before) break;
        }

        const loc = self.currentLoc();
        const ch = self.peek();

        if ((ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z') or ch == '_') return self.readIdentifier();
        if ((ch >= '0' and ch <= '9') or ch == '-') return self.readNumber();
        if (ch == '"') return self.readString();

        switch (ch) {
            '{' => {
                self.advance();
                return Token{ .kind = .l_brace, .lexeme = self.src[self.index - 1 .. self.index], .loc = loc, .int_value = 0 };
            },
            '}' => {
                self.advance();
                return Token{ .kind = .r_brace, .lexeme = self.src[self.index - 1 .. self.index], .loc = loc, .int_value = 0 };
            },
            '(' => {
                self.advance();
                return Token{ .kind = .l_paren, .lexeme = self.src[self.index - 1 .. self.index], .loc = loc, .int_value = 0 };
            },
            ')' => {
                self.advance();
                return Token{ .kind = .r_paren, .lexeme = self.src[self.index - 1 .. self.index], .loc = loc, .int_value = 0 };
            },
            ':' => {
                self.advance();
                return Token{ .kind = .colon, .lexeme = self.src[self.index - 1 .. self.index], .loc = loc, .int_value = 0 };
            },
            '.' => {
                self.advance();
                return Token{ .kind = .dot, .lexeme = self.src[self.index - 1 .. self.index], .loc = loc, .int_value = 0 };
            },
            '*' => {
                self.advance();
                return Token{ .kind = .star, .lexeme = self.src[self.index - 1 .. self.index], .loc = loc, .int_value = 0 };
            },
            '+' => {
                self.advance();
                if (self.peek() == '=') {
                    self.advance();
                    return Token{ .kind = .plus_equals, .lexeme = self.src[self.index - 2 .. self.index], .loc = loc, .int_value = 0 };
                }
                return error.InvalidCharacter; // '+' by itself is not valid
            },
            '=' => {
                self.advance();
                return Token{ .kind = .equals, .lexeme = self.src[self.index - 1 .. self.index], .loc = loc, .int_value = 0 };
            },
            ';' => {
                self.advance();
                return Token{ .kind = .semicolon, .lexeme = self.src[self.index - 1 .. self.index], .loc = loc, .int_value = 0 };
            },
            else => return error.InvalidCharacter,
        }
    }
};
