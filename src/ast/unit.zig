const SourceLoc = @import("../parser/token.zig").SourceLoc;
const MapDecl = @import("map.zig").MapDecl;

pub const Unit = struct {
    name: []const u8,
    loc: SourceLoc,
    sections: []const []const u8,
    license: ?[]const u8,
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

pub const HeapLookup = struct {
    map_name: []const u8,
    key_expr: *Expr,
};

pub const HeapVarDecl = struct {
    name: []const u8,
    lookup: HeapLookup,
};
