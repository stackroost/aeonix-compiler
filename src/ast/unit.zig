const std = @import("std");
const SourceLoc = @import("../parser/token.zig").SourceLoc;

pub const Unit = struct {
    name: []const u8,
    loc: SourceLoc,

    /// Kernel attach points
    sections: []const []const u8,

    /// ELF license (default filled in sema)
    license: ?[]const u8,

    /// BPF maps (persistent kernel storage)
    maps: []MapDecl,

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
    VarDecl: VarDecl,
};

pub const VarDecl = struct {
    name: []const u8,
    is_mutable: bool, // true for reg, false for imm
    value: i64,
};

pub const MapDecl = struct {
    name: []const u8,
    map_type: MapType,
    key_type: Type,
    value_type: Type,
    max_entries: u32,
    loc: SourceLoc,
};

pub const MapType = enum {
    hash,
    array,
    ringbuf,
    lru_hash,
    prog_array,
};

pub const Type = enum {
    u32,
    u64,
    i32,
    i64,
};
