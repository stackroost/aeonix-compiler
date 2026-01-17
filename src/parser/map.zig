const std = @import("std");
const ast = @import("../ast/map.zig");
const Parser = @import("parser.zig").Parser;

/// Parses a map declaration, e.g.:
/// map connection_counter {
///     type: .hash;
///     key: u32;
///     value: u64;
///     max: 1024;
/// }
pub fn parseMap(self: *Parser) Parser.ParseError!ast.MapDecl {
    const map_loc = self.current.loc;

    // Map name
    const map_name_tok = try self.expect(.identifier);
    _ = try self.expect(.l_brace);

    var map_type: ?ast.MapType = null;
    var key_type: ?ast.Type = null;
    var value_type: ?ast.Type = null;
    var max_entries: ?u32 = null;

    while (!self.check(.r_brace)) {
        // --- type ---
        if (self.match(.keyword_type)) {
            _ = try self.expect(.colon);

            _ = try self.expect(.dot);
            const t_tok = try self.expect(.identifier);
            // assign map_type using string comparison
            if (std.mem.eql(u8, t_tok.lexeme, "hash")) {
                map_type = .hash;
            } else if (std.mem.eql(u8, t_tok.lexeme, "array")) {
                map_type = .array;
            } else if (std.mem.eql(u8, t_tok.lexeme, "ringbuf")) {
                map_type = .ringbuf;
            } else if (std.mem.eql(u8, t_tok.lexeme, "lru_hash")) {
                map_type = .lru_hash;
            } else if (std.mem.eql(u8, t_tok.lexeme, "prog_array")) {
                map_type = .prog_array;
            } else {
                return self.parseError("expected map type");
            }

            _ = try self.expect(.semicolon); // expect ';'
            continue;
        }

        // --- key type ---
        if (self.match(.keyword_key)) {
            _ = try self.expect(.colon);
            key_type = try parseType(self);
            _ = try self.expect(.semicolon);
            continue;
        }

        // --- value type ---
        if (self.match(.keyword_value)) {
            _ = try self.expect(.colon);
            value_type = try parseType(self);
            _ = try self.expect(.semicolon);
            continue;
        }

        // --- max entries ---
        if (self.match(.keyword_max)) {
            _ = try self.expect(.colon);
            const n = try self.expect(.number);
            if (n.int_value < 0) return self.parseError("max must be >= 0");
            max_entries = @as(u32, @intCast(n.int_value));
            _ = try self.expect(.semicolon);
            continue;
        }

        // Unexpected token inside map
        return self.parseError("unexpected token in map");
    }

    // --- closing brace ---
    _ = try self.expect(.r_brace);

    // --- validate required fields ---
    if (map_type == null or key_type == null or value_type == null or max_entries == null) {
        return self.parseError("map missing required fields: type, key, value, max");
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

/// Parses simple types for key/value fields
fn parseType(self: *Parser) Parser.ParseError!ast.Type {
    const t = self.current;
    _ = try self.advance();

    switch (t.kind) {
        .type_u32 => return .u32,
        .type_u64 => return .u64,
        .type_i32 => return .i32,
        .type_i64 => return .i64,
        else => return self.parseError("expected type"),
    }
}
