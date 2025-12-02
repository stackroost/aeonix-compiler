const std = @import("std");
const Lexer = @import("lexer.zig");
const Ast = @import("ast.zig");

pub fn parse(tokens: []const Lexer.Token) !Ast.Ast {
    var i: usize = 0;
    const next = comptime fn () Lexer.Token {
        if (i < tokens.len) return tokens[i]; else return Lexer.Token{ .kind = .Eof, .slice = "" };
    };

    // very small parser for `unit main() { emitln "..." }`
    // returns Ast with one top-level unit and a list of statements.
    var ast = Ast.Ast.init();

    // expect 'unit'
    if (tokens[i].kind != .Unit) return error.InvalidSyntax;
    i += 1;
    // name (identifier)
    if (tokens[i].kind != .Identifier) return error.InvalidSyntax;
    const unit_name = tokens[i].slice;
    i += 1;
    // expect '(' ')'
    if (tokens[i].kind != .LParen) return error.InvalidSyntax; i += 1;
    if (tokens[i].kind != .RParen) return error.InvalidSyntax; i += 1;
    // expect '{'
    if (tokens[i].kind != .LBrace) return error.InvalidSyntax; i += 1;

    while (tokens[i].kind != .RBrace and tokens[i].kind != .Eof) {
        if (tokens[i].kind == .Emit or tokens[i].kind == .Emitln) {
            const isln = tokens[i].kind == .Emitln;
            i += 1;
            // expect string
            if (tokens[i].kind != .StringLit) return error.InvalidSyntax;
            const s = tokens[i].slice;
            try ast.addStatement(Ast.StatementEmit{ .msg = s, .newline = isln });
            i += 1;
            continue;
        } else {
            // skip unknown tokens for now
            i += 1;
        }
    }
    // done
    return ast;
}

pub const error = error{ InvalidSyntax };
