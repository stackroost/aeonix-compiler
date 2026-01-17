const std = @import("std");
const ast = @import("../ast/mod.zig");
const Parser = @import("parser.zig").Parser;
const parseMap = @import("map.zig").parseMap;

fn parseStmt(self: *Parser, body: *std.ArrayList(ast.Stmt)) Parser.ParseError!void {
    if (self.match(.keyword_reg)) {
        const var_loc = self.current.loc;
        const var_name_tok = try self.expect(.identifier);
        _ = try self.expect(.equals);
        const value_expr = try self.parseExpr();
        _ = try self.expect(.semicolon);

        try body.append(self.allocator, .{
            .kind = .{ .VarDecl = .{
                .name = try self.allocator.dupe(u8, var_name_tok.lexeme),
                .var_type = .reg,
                .value = value_expr,
            } },
            .loc = var_loc,
        });
        return;
    }

    if (self.match(.keyword_imm)) {
        const var_loc = self.current.loc;
        const var_name_tok = try self.expect(.identifier);
        _ = try self.expect(.equals);
        const value_expr = try self.parseExpr();
        _ = try self.expect(.semicolon);

        try body.append(self.allocator, .{
            .kind = .{ .VarDecl = .{
                .name = try self.allocator.dupe(u8, var_name_tok.lexeme),
                .var_type = .imm,
                .value = value_expr,
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
        _ = try self.expect(.semicolon);

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
        const v = try self.parseExpr();
        _ = try self.expect(.semicolon);

        try body.append(self.allocator, .{
            .kind = .{ .Return = v },
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

        var guard_body = try std.ArrayList(ast.Stmt).initCapacity(self.allocator, 0);
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

    const target = try self.parseExpr();
    if (self.match(.equals)) {
        const value = try self.parseExpr();
        _ = try self.expect(.semicolon);
        try body.append(self.allocator, .{
            .kind = .{ .Assignment = .{
                .target = target,
                .op = "=",
                .value = value,
            } },
            .loc = target.loc,
        });
        return;
    } else if (self.match(.plus_equals)) {
        const value = try self.parseExpr();
        _ = try self.expect(.semicolon);
        try body.append(self.allocator, .{
            .kind = .{ .Assignment = .{
                .target = target,
                .op = "+=",
                .value = value,
            } },
            .loc = target.loc,
        });
        std.debug.print("[DEBUG] Parsed assignment\n", .{});
        return;
    }

    return self.parseError("unexpected statement");
}

pub fn parseExpr(self: *Parser) Parser.ParseError!*ast.Expr {
    if (self.check(.star)) {
        _ = try self.expect(.star);
        const inner = try self.parseExpr();
        const expr = try self.allocator.create(ast.Expr);
        expr.* = .{
            .kind = .{ .Dereference = inner },
            .loc = inner.loc,
        };
        return expr;
    }

    if (self.check(.number)) {
        const num_tok = try self.expect(.number);
        const expr = try self.allocator.create(ast.Expr);
        expr.* = .{
            .kind = .{ .Number = num_tok.int_value },
            .loc = num_tok.loc,
        };
        return expr;
    }

    const receiver_tok = try self.expect(.identifier);

    if (self.match(.dot)) {
        const method_tok = try self.expect(.identifier);
        _ = try self.expect(.l_paren);
        const arg = try self.parseExpr();
        _ = try self.expect(.r_paren);

        const expr = try self.allocator.create(ast.Expr);
        expr.* = .{
            .kind = .{ .MethodCall = .{
                .receiver = try self.allocator.dupe(u8, receiver_tok.lexeme),
                .method = try self.allocator.dupe(u8, method_tok.lexeme),
                .arg = arg,
            } },
            .loc = receiver_tok.loc,
        };
        return expr;
    } else {
        const expr = try self.allocator.create(ast.Expr);
        expr.* = .{
            .kind = .{ .VarRef = try self.allocator.dupe(u8, receiver_tok.lexeme) },
            .loc = receiver_tok.loc,
        };
        return expr;
    }
}

pub fn parseUnit(self: *Parser) Parser.ParseError!ast.Unit {
    const unit_loc = self.current.loc;
    _ = try self.expect(.keyword_unit);

    const name_tok = try self.expect(.identifier);
    std.debug.print("[DEBUG] Parsing unit: {s}\n", .{name_tok.lexeme});
    _ = try self.expect(.l_brace);

    var sections = try std.ArrayList([]const u8).initCapacity(self.allocator, 0);
    var body = try std.ArrayList(ast.Stmt).initCapacity(self.allocator, 0);
    var license: ?[]const u8 = null;

    while (!self.match(.r_brace)) {
        if (self.match(.keyword_section)) {
            _ = try self.expect(.colon);
            const s = try self.expect(.string_literal);
            const txt = if (s.lexeme.len >= 2) s.lexeme[1 .. s.lexeme.len - 1] else "";
            try sections.append(self.allocator, try self.allocator.dupe(u8, txt));
            _ = try self.expect(.semicolon);
            std.debug.print("[DEBUG] Parsed section\n", .{});
            continue;
        }

        if (self.match(.keyword_license)) {
            _ = try self.expect(.colon);
            const s = try self.expect(.string_literal);
            const txt = if (s.lexeme.len >= 2) s.lexeme[1 .. s.lexeme.len - 1] else "";
            license = try self.allocator.dupe(u8, txt);
            _ = try self.expect(.semicolon);
            std.debug.print("[DEBUG] Parsed license\n", .{});
            continue;
        }

        try parseStmt(self, &body);
    }

    std.debug.print("[DEBUG] Finished parsing unit\n", .{});

    return ast.Unit{
        .name = try self.allocator.dupe(u8, name_tok.lexeme),
        .loc = unit_loc,
        .sections = try sections.toOwnedSlice(self.allocator),
        .license = license,
        .body = try body.toOwnedSlice(self.allocator),
    };
}
