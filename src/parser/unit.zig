const std = @import("std");
const ast = @import("../ast/mod.zig");
const Parser = @import("parser.zig").Parser;
const parseMap = @import("map.zig").parseMap;

fn parseStmt(self: *Parser, body: *std.ArrayList(ast.Stmt)) Parser.ParseError!void {
    if (self.match(.keyword_reg)) {
        const var_loc = self.current.loc;
        const var_name_tok = try self.expect(.identifier);
        _ = try self.expect(.equals);
        const value_tok = try self.expect(.number);

        try body.append(self.allocator, .{
            .kind = .{ .VarDecl = .{
                .name = try self.allocator.dupe(u8, var_name_tok.lexeme),
                .var_type = .reg,
                .value = value_tok.int_value,
            } },
            .loc = var_loc,
        });
        return;
    }

    if (self.match(.keyword_imm)) {
        const var_loc = self.current.loc;
        const var_name_tok = try self.expect(.identifier);
        _ = try self.expect(.equals);
        const value_tok = try self.expect(.number);

        try body.append(self.allocator, .{
            .kind = .{ .VarDecl = .{
                .name = try self.allocator.dupe(u8, var_name_tok.lexeme),
                .var_type = .imm,
                .value = value_tok.int_value,
            } },
            .loc = var_loc,
        });
        return;
    }

    if (self.match(.keyword_heap)) {
        const var_loc = self.current.loc;
        const var_name_tok = try self.expect(.identifier);
        _ = try self.expect(.equals);

        const map_name_tok = try self.expect(.identifier);
        _ = try self.expect(.dot);
        const lookup_tok = try self.expect(.identifier);
        if (!std.mem.eql(u8, lookup_tok.lexeme, "lookup")) {
            return self.parseError("expected 'lookup'");
        }

        _ = try self.expect(.l_paren);
        const key_expr = try self.parseExpr();
        _ = try self.expect(.r_paren);

        try body.append(self.allocator, .{
            .kind = .{ .HeapVarDecl = .{
                .name = try self.allocator.dupe(u8, var_name_tok.lexeme),
                .lookup = .{
                    .map_name = try self.allocator.dupe(u8, map_name_tok.lexeme),
                    .key_expr = key_expr,
                },
            } },
            .loc = var_loc,
        });
        return;
    }

    if (self.match(.keyword_return)) {
        const return_loc = self.current.loc;
        const v = try self.expect(.number);

        try body.append(self.allocator, .{
            .kind = .{ .Return = v.int_value },
            .loc = return_loc,
        });
        return;
    }

    if (self.match(.keyword_if)) {
        const if_loc = self.current.loc;
        _ = try self.expect(.keyword_guard);
        _ = try self.expect(.l_paren);
        const var_tok = try self.expect(.identifier);
        _ = try self.expect(.r_paren);
        _ = try self.expect(.l_brace);

        var guard_body = std.ArrayList(ast.Stmt).init(self.allocator);
        while (!self.match(.r_brace)) {
            try parseStmt(self, &guard_body);
        }

        try body.append(self.allocator, .{
            .kind = .{ .IfGuard = .{
                .condition = .{
                    .kind = .{ .VarRef = try self.allocator.dupe(u8, var_tok.lexeme) },
                    .loc = var_tok.loc,
                },
                .body = try guard_body.toOwnedSlice(self.allocator),
            } },
            .loc = if_loc,
        });
        return;
    }

    return self.parseError("unexpected statement");
}

// -------------------- Expression Parsing --------------------
pub fn parseExpr(self: *Parser) Parser.ParseError!*ast.Expr {
    if (self.match(.star)) {
        const inner = try self.parseExpr();
        const expr = try self.allocator.create(ast.Expr);
        expr.* = .{
            .kind = .{ .Dereference = inner },
            .loc = inner.loc,
        };
        return expr;
    }

    const tok = try self.expect(.identifier);
    const expr = try self.allocator.create(ast.Expr);
    expr.* = .{
        .kind = .{ .VarRef = try self.allocator.dupe(u8, tok.lexeme) },
        .loc = tok.loc,
    };
    return expr;
}
pub fn parseUnit(self: *Parser) Parser.ParseError!ast.Unit {
    const unit_loc = self.current.loc;
    _ = try self.expect(.keyword_unit);

    const name_tok = try self.expect(.identifier);
    _ = try self.expect(.l_brace);

    var sections = std.ArrayList([]const u8).init(self.allocator);
    var maps = std.ArrayList(ast.MapDecl).init(self.allocator);
    var body = std.ArrayList(ast.Stmt).init(self.allocator);
    var license: ?[]const u8 = null;

    while (!self.match(.r_brace)) {
        if (self.match(.keyword_section)) {
            const s = try self.expect(.string_literal);
            const txt = if (s.lexeme.len >= 2) s.lexeme[1 .. s.lexeme.len - 1] else "";
            try sections.append(try self.allocator.dupe(u8, txt));
            continue;
        }

        if (self.match(.keyword_license)) {
            const s = try self.expect(.string_literal);
            const txt = if (s.lexeme.len >= 2) s.lexeme[1 .. s.lexeme.len - 1] else "";
            license = try self.allocator.dupe(u8, txt);
            continue;
        }

        if (self.match(.keyword_map)) {
            const m = try parseMap(self);
            try maps.append(m);
            continue;
        }

        try parseStmt(self, &body);
    }

    return ast.Unit{
        .name = try self.allocator.dupe(u8, name_tok.lexeme),
        .loc = unit_loc,
        .sections = try sections.toOwnedSlice(self.allocator),
        .license = license,
        .maps = try maps.toOwnedSlice(self.allocator),
        .body = try body.toOwnedSlice(self.allocator),
    };
}
