const std = @import("std");
const SourceLoc = @import("../parser/token.zig").SourceLoc;

pub const Unit = struct {
    name: []const u8,
    loc: SourceLoc,

    /// Kernel attach points
    sections: []const []const u8,

    /// ELF license (default filled in sema)
    license: ?[]const u8,

    /// Body statements
    body: []Stmt,
};

/// Placeholder until full stmt system
pub const Stmt = struct {
    kind: StmtKind,
    loc: SourceLoc,
};

pub const StmtKind = union(enum) {
    Return: i64,
    // Reg, State, Guard later
};
