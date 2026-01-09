// parser/unit.zig
const std = @import("std");
const ast = @import("../ast/unit.zig");
const Parser = @import("parser.zig").Parser;

pub fn parseUnit(self: *Parser) Parser.ParseError!ast.Unit {
    const unit_loc = self.current.loc;
    _ = try self.expect(.keyword_unit);

    const name_tok = try self.expect(.identifier);
    _ = try self.expect(.l_brace);

    var sections = try std.ArrayList([]const u8).initCapacity(self.allocator, 4);
    var license: ?[]const u8 = null;
    var body = try std.ArrayList(ast.Stmt).initCapacity(self.allocator, 8);

    while (!self.match(.r_brace)) {
        if (self.match(.keyword_section)) {
            const s = try self.expect(.string_literal);
            const content =
                if (s.lexeme.len >= 2) s.lexeme[1 .. s.lexeme.len - 1] else "";
            try sections.append(
                self.allocator,
                try self.allocator.dupe(u8, content),
            );
            continue;
        }

        if (self.match(.keyword_license)) {
            const l = try self.expect(.string_literal);
            const content =
                if (l.lexeme.len >= 2) l.lexeme[1 .. l.lexeme.len - 1] else "";
            license = try self.allocator.dupe(u8, content);
            continue;
        }

        if (self.match(.keyword_reg)) {
            const var_loc = self.current.loc;
            const var_name_tok = try self.expect(.identifier);
            _ = try self.expect(.equals);
            const value_tok = try self.expect(.number);
            try body.append(self.allocator, .{
                .kind = .{
                    .VarDecl = .{
                        .name = try self.allocator.dupe(u8, var_name_tok.lexeme),
                        .is_mutable = true,
                        .value = value_tok.int_value,
                    },
                },
                .loc = var_loc,
            });
            continue;
        }

        if (self.match(.keyword_imm)) {
            const var_loc = self.current.loc;
            const var_name_tok = try self.expect(.identifier);
            _ = try self.expect(.equals);
            const value_tok = try self.expect(.number);
            try body.append(self.allocator, .{
                .kind = .{
                    .VarDecl = .{
                        .name = try self.allocator.dupe(u8, var_name_tok.lexeme),
                        .is_mutable = false,
                        .value = value_tok.int_value,
                    },
                },
                .loc = var_loc,
            });
            continue;
        }

        if (self.match(.keyword_return)) {
            const return_loc = self.current.loc;
            const v = try self.expect(.number);
            try body.append(self.allocator, .{
                .kind = .{ .Return = v.int_value },
                .loc = return_loc,
            });
            continue;
        }

        return self.parseError("unexpected token in unit");
    }

    return ast.Unit{
        .name = try self.allocator.dupe(u8, name_tok.lexeme),
        .loc = unit_loc,
        .sections = try sections.toOwnedSlice(self.allocator),
        .license = if (license) |l|
            try self.allocator.dupe(u8, l)
        else
            null,
        .body = try body.toOwnedSlice(self.allocator),
    };
}
