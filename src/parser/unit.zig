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
    var maps = try std.ArrayList(ast.MapDecl).initCapacity(self.allocator, 4);
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

        if (self.match(.keyword_map)) {
            const map_loc = self.current.loc;
            const map_name_tok = try self.expect(.identifier);
            _ = try self.expect(.l_brace);

            var map_type: ?ast.MapType = null;
            var key_type: ?ast.Type = null;
            var value_type: ?ast.Type = null;
            var max_entries: ?u32 = null;

            while (!self.match(.r_brace)) {
                if (self.match(.keyword_type)) {
                    _ = try self.expect(.colon);
                    const type_tok = self.current;
                    map_type = switch (type_tok.kind) {
                        .map_type_hash => ast.MapType.hash,
                        .map_type_array => ast.MapType.array,
                        .map_type_ringbuf => ast.MapType.ringbuf,
                        .map_type_lru_hash => ast.MapType.lru_hash,
                        .map_type_prog_array => ast.MapType.prog_array,
                        else => return self.parseError("expected map type"),
                    };
                    _ = try self.advance();
                    continue;
                }

                if (self.match(.keyword_key)) {
                    _ = try self.expect(.colon);
                    const type_tok = self.current;
                    key_type = switch (type_tok.kind) {
                        .type_u32 => ast.Type.u32,
                        .type_u64 => ast.Type.u64,
                        .type_i32 => ast.Type.i32,
                        .type_i64 => ast.Type.i64,
                        else => return self.parseError("expected type for key"),
                    };
                    _ = try self.advance();
                    continue;
                }

                if (self.match(.keyword_value)) {
                    _ = try self.expect(.colon);
                    const type_tok = self.current;
                    value_type = switch (type_tok.kind) {
                        .type_u32 => ast.Type.u32,
                        .type_u64 => ast.Type.u64,
                        .type_i32 => ast.Type.i32,
                        .type_i64 => ast.Type.i64,
                        else => return self.parseError("expected type for value"),
                    };
                    _ = try self.advance();
                    continue;
                }

                if (self.match(.keyword_max)) {
                    _ = try self.expect(.colon);
                    const max_tok = try self.expect(.number);
                    if (max_tok.int_value < 0) {
                        return self.parseError("max_entries must be non-negative");
                    }
                    max_entries = @as(u32, @intCast(max_tok.int_value));
                    continue;
                }

                return self.parseError("unexpected token in map declaration");
            }

            if (map_type == null or key_type == null or value_type == null or max_entries == null) {
                return self.parseError("map declaration missing required fields (type, key, value, max)");
            }

            try maps.append(self.allocator, .{
                .name = try self.allocator.dupe(u8, map_name_tok.lexeme),
                .map_type = map_type.?,
                .key_type = key_type.?,
                .value_type = value_type.?,
                .max_entries = max_entries.?,
                .loc = map_loc,
            });
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
        .maps = try maps.toOwnedSlice(self.allocator),
        .body = try body.toOwnedSlice(self.allocator),
    };
}
