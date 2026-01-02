const std = @import("std");

pub const Unit = struct {
    name: []const u8,

    /// Kernel attach points
    sections: []const []const u8,

    /// ELF license (default filled in sema)
    license: ?[]const u8,

    /// Body statements
    body: []Stmt,
};

/// Placeholder until full stmt system
pub const Stmt = union(enum) {
    Return: i64,
    // Reg, State, Guard later
};
