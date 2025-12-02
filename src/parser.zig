const std = @import("std");
const Lexer = @import("lexer.zig");
const Ast = @import("ast.zig");

pub fn parse(tokens: []const Lexer.Token) !Ast.Ast {
    var i: usize = 0;

    // very small parser for `unit main() { emitln "..." }`
    // returns Ast with one top-level unit and a list of statements.
    var ast = try Ast.Ast.init();

    // expect 'unit'
    if (tokens[i].kind != .Unit) return ParserError.InvalidSyntax;
    i += 1;
    // name (identifier)
    if (tokens[i].kind != .Identifier) return ParserError.InvalidSyntax;
    i += 1;
    // expect '(' ')'
    if (tokens[i].kind != .LParen) return ParserError.InvalidSyntax;
    i += 1;
    if (tokens[i].kind != .RParen) return ParserError.InvalidSyntax;
    i += 1;
    // expect '{'
    if (tokens[i].kind != .LBrace) return ParserError.InvalidSyntax;
    i += 1;

    while (tokens[i].kind != .RBrace and tokens[i].kind != .Eof) {
        if (tokens[i].kind == .Emit or tokens[i].kind == .Emitln) {
            const isln = tokens[i].kind == .Emitln;
            i += 1;
            // expect string
            if (tokens[i].kind != .StringLit) return ParserError.InvalidSyntax;
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

pub const ParserError = error{InvalidSyntax};
