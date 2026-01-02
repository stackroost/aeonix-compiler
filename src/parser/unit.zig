// parser/unit.zig
const std = @import("std");
const ast = @import("../ast/unit.zig");
const Parser = @import("parser.zig").Parser;

pub fn parseUnit(self: *Parser) !ast.Unit {
    try self.expect(.keyword_unit);

    const name_tok = try self.expect(.identifier);
    try self.expect(.l_brace);

    var sections = std.ArrayList([]const u8).init(self.allocator);
    var license: ?[]const u8 = null;
    var body = std.ArrayList(ast.Stmt).init(self.allocator);

    while (!self.match(.r_brace)) {
        if (self.match(.keyword_section)) {
            const s = try self.expect(.string_literal);
            try sections.append(s.lexeme);
            continue;
        }

        if (self.match(.keyword_license)) {
            const l = try self.expect(.string_literal);
            license = l.lexeme;
            continue;
        }

        if (self.match(.keyword_return)) {
            const v = try self.expect(.number);
            try body.append(.{ .Return = v.int_value });
            continue;
        }

        return self.parseError("unexpected token in unit");
    }

    return ast.Unit{
        .name = name_tok.lexeme,
        .sections = sections.toOwnedSlice(),
        .license = license,
        .body = body.toOwnedSlice(),
    };
}
