const parser = @import("parser.zig");

pub fn check(ast: *parser.Ast) !void {
    _ = ast;
    // Stage-0: add keyword checks + "all paths return" later
}
