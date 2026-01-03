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
        if (self.index >= self.src.len) {
            return 0;
        }
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
            if (ch == ' ' or ch == '\t' or ch == '\r') {
                self.advance();
            } else if (ch == '\n') {
                self.advance();
            } else {
                break;
            }
        }
    }

    fn skipComment(self: *Lexer) !void {
        if (self.peek() == '/') {
            self.advance();
            if (self.peek() == '/') {
                // Single-line comment
                self.advance();
                while (self.index < self.src.len and self.src[self.index] != '\n') {
                    self.advance();
                }
                if (self.index < self.src.len) {
                    self.advance(); // consume newline
                }
            } else if (self.peek() == '*') {
                // Multi-line comment
                self.advance();
                while (self.index < self.src.len) {
                    if (self.src[self.index] == '*' and self.index + 1 < self.src.len and self.src[self.index + 1] == '/') {
                        self.advance(); // consume *
                        self.advance(); // consume /
                        return;
                    }
                    self.advance();
                }
                return error.UnterminatedComment;
            } else {
                // Not a comment, backtrack
                self.index -= 1;
                self.column -= 1;
            }
        }
    }

    fn isKeyword(self: *const Lexer, start: usize, keyword: []const u8) bool {
        if (self.index - start != keyword.len) {
            return false;
        }
        return std.mem.eql(u8, self.src[start..self.index], keyword);
    }

    fn readIdentifier(self: *Lexer) Token {
        const start = self.index;
        const loc = self.currentLoc();

        while (self.index < self.src.len) {
            const ch = self.peek();
            if ((ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z') or (ch >= '0' and ch <= '9') or ch == '_') {
                self.advance();
            } else {
                break;
            }
        }

        const lexeme = self.src[start..self.index];

        // Check for keywords
        const kind: TokenKind = if (std.mem.eql(u8, lexeme, "unit")) .keyword_unit
        else if (std.mem.eql(u8, lexeme, "section")) .keyword_section
        else if (std.mem.eql(u8, lexeme, "license")) .keyword_license
        else if (std.mem.eql(u8, lexeme, "return")) .keyword_return
        else .identifier;

        return Token{
            .kind = kind,
            .lexeme = lexeme,
            .loc = loc,
            .int_value = 0,
        };
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

        while (self.index < self.src.len) {
            const ch = self.peek();
            if (ch >= '0' and ch <= '9') {
                value = value * 10 + @as(i64, ch - '0');
                self.advance();
            } else {
                break;
            }
        }

        if (negative) {
            value = -value;
        }

        const lexeme = self.src[start..self.index];

        return Token{
            .kind = .number,
            .lexeme = lexeme,
            .loc = loc,
            .int_value = value,
        };
    }

    fn readString(self: *Lexer) !Token {
        const start = self.index;
        const loc = self.currentLoc();

        if (self.peek() != '"') {
            return error.ExpectedStringLiteral;
        }
        self.advance(); // consume opening quote

        while (self.index < self.src.len) {
            const ch = self.peek();
            if (ch == '"') {
                self.advance(); // consume closing quote
                const lexeme = self.src[start..self.index];
                return Token{
                    .kind = .string_literal,
                    .lexeme = lexeme,
                    .loc = loc,
                    .int_value = 0,
                };
            } else if (ch == '\\') {
                // Handle escape sequences
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
        // Skip whitespace and comments
        while (true) {
            self.skipWhitespace();
            if (self.index >= self.src.len) {
                return Token{
                    .kind = .eof,
                    .lexeme = "",
                    .loc = self.currentLoc(),
                    .int_value = 0,
                };
            }

            // Try to skip comment
            const before = self.index;
            self.skipComment() catch |err| {
                if (err == error.UnterminatedComment) {
                    return Token{
                        .kind = .eof,
                        .lexeme = "",
                        .loc = self.currentLoc(),
                        .int_value = 0,
                    };
                }
                return err;
            };
            if (self.index == before) {
                break; // No comment skipped, proceed with tokenization
            }
        }

        const loc = self.currentLoc();
        const ch = self.peek();

        // Identifiers and keywords
        if ((ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z') or ch == '_') {
            return self.readIdentifier();
        }

        // Numbers
        if ((ch >= '0' and ch <= '9') or ch == '-') {
            return self.readNumber();
        }

        // String literals
        if (ch == '"') {
            return self.readString();
        }

        // Punctuation
        switch (ch) {
            '{' => {
                self.advance();
                return Token{
                    .kind = .l_brace,
                    .lexeme = self.src[self.index - 1..self.index],
                    .loc = loc,
                    .int_value = 0,
                };
            },
            '}' => {
                self.advance();
                return Token{
                    .kind = .r_brace,
                    .lexeme = self.src[self.index - 1..self.index],
                    .loc = loc,
                    .int_value = 0,
                };
            },
            else => {
                return error.InvalidCharacter;
            },
        }
    }
};
