const std = @import("std");

pub const TokenKind = enum {
    Unit,
    Identifier,
    LParen,
    RParen,
    LBrace,
    RBrace,
    Emit,
    Emitln,
    StringLit,
    Eof,
};

pub const Token = struct {
    kind: TokenKind,
    slice: []const u8,
    pub fn toString(self: Token) []const u8 {
        return self.slice;
    }
};

pub fn tokenize(buf: []const u8) ![]Token {
    var arena = std.heap.page_allocator;
    var list = std.ArrayList(Token).init(arena);
    var i: usize = 0;
    while (i < buf.len) : (i += 1) {
        const c = buf[i];
        if (c == ' ' or c == '\t' or c == '\n' or c == '\r') continue;
        if (c == '(') { try list.append(Token{ .kind = .LParen, .slice = "(" }); continue; }
        if (c == ')') { try list.append(Token{ .kind = .RParen, .slice = ")" }); continue; }
        if (c == '{') { try list.append(Token{ .kind = .LBrace, .slice = "{" }); continue; }
        if (c == '}') { try list.append(Token{ .kind = .RBrace, .slice = "}" }); continue; }
        if (c == '"') {
            var j = i + 1;
            while (j < buf.len and buf[j] != '"') j += 1;
            if (j >= buf.len) return error.BadString;
            const s = buf[i+1 .. j];
            try list.append(Token{ .kind = .StringLit, .slice = s });
            i = j;
            continue;
        }
        // identifier / keyword
        if ((c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_') {
            var j = i;
            while (j < buf.len) {
                const cc = buf[j];
                if (!((cc >= 'a' and cc <= 'z') or (cc >= 'A' and cc <= 'Z') or (cc >= '0' and cc <= '9') or cc == '_')) break;
                j += 1;
            }
            const name = buf[i .. j];
            if (std.mem.eql(u8, name, "unit")) {
                try list.append(Token{ .kind = .Unit, .slice = name });
            } else if (std.mem.eql(u8, name, "emitln")) {
                try list.append(Token{ .kind = .Emitln, .slice = name });
            } else if (std.mem.eql(u8, name, "emit")) {
                try list.append(Token{ .kind = .Emit, .slice = name });
            } else {
                try list.append(Token{ .kind = .Identifier, .slice = name });
            }
            i = j - 1;
            continue;
        }
        // fallback: ignore unknown char
    }
    try list.append(Token{ .kind = .Eof, .slice = "" });
    return list.toOwnedSlice();
}

pub const error = error{ BadString };
