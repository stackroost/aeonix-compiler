const std = @import("std");
const ast = @import("../ast/map.zig");
const Parser = @import("parser.zig").Parser;

pub fn parseMap(self: *Parser) Parser.ParseError!ast.MapDecl {
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
            const t = self.current;
            map_type = switch (t.kind) {
                .map_type_hash => .hash,
                .map_type_array => .array,
                .map_type_ringbuf => .ringbuf,
                .map_type_lru_hash => .lru_hash,
                .map_type_prog_array => .prog_array,
                else => return self.parseError("expected map type"),
            };
            _ = try self.advance();
            continue;
        }

        if (self.match(.keyword_key)) {
            _ = try self.expect(.colon);
            key_type = try parseType(self);
            continue;
        }

        if (self.match(.keyword_value)) {
            _ = try self.expect(.colon);
            value_type = try parseType(self);
            continue;
        }

        if (self.match(.keyword_max)) {
            _ = try self.expect(.colon);
            const n = try self.expect(.number);
            if (n.int_value < 0) return self.parseError("max must be >= 0");
            max_entries = @as(u32, @intCast(n.int_value));
            continue;
        }

        return self.parseError("unexpected token in map");
    }

    if (map_type == null or key_type == null or value_type == null or max_entries == null) {
        return self.parseError("map missing fields: type, key, value, max");
    }

    return .{
        .name = try self.allocator.dupe(u8, map_name_tok.lexeme),
        .map_type = map_type.?,
        .key_type = key_type.?,
        .value_type = value_type.?,
        .max_entries = max_entries.?,
        .loc = map_loc,
    };
}

fn parseType(self: *Parser) Parser.ParseError!ast.Type {
    const t = self.current;
    _ = try self.advance();
    return switch (t.kind) {
        .type_u32 => .u32,
        .type_u64 => .u64,
        .type_i32 => .i32,
        .type_i64 => .i64,
        else => self.parseError("expected type"),
    };
}
