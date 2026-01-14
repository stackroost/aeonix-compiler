const std = @import("std");
const SourceLoc = @import("../parser/token.zig").SourceLoc;

pub const Program = struct {
    maps: []MapDecl,
    units: []Unit,
};

pub const Unit = struct {
    name: []const u8,
    loc: SourceLoc,

    
    sections: []const []const u8,

    
    license: ?[]const u8,

    
    maps: []MapDecl,

    
    body: []Stmt,
};


pub const Stmt = struct {
    kind: StmtKind,
    loc: SourceLoc,
};

pub const StmtKind = union(enum) {
    Return: i64,
    VarDecl: VarDecl,
    HeapVarDecl: HeapVarDecl,
    IfGuard: IfGuard,
};

pub const IfGuard = struct {
    condition: Expr,
    body: []Stmt,
};

pub const Expr = struct {
    kind: ExprKind,
    loc: SourceLoc,
};

pub const ExprKind = union(enum) {
    VarRef: []const u8, 
    HeapLookup: HeapLookup, 
    Dereference: *Expr, 
    
};

pub const VarDecl = struct {
    name: []const u8,
    var_type: VarType,
    value: i64,
};

pub const VarType = enum {
    reg, 
    imm, 
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
    perf_event_array,
};

pub const Type = enum {
    u32,
    u64,
    i32,
    i64,
};

pub const HeapLookup = struct {
    map_name: []const u8,
    key_expr: *Expr,
};

pub const HeapVarDecl = struct {
    name: []const u8,
    lookup: HeapLookup,
};
