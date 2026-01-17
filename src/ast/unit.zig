const SourceLoc = @import("../parser/token.zig").SourceLoc;
pub const MapDecl = @import("map.zig").MapDecl; // re-export map type

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
    Return: *Expr,
    VarDecl: VarDecl,
    HeapVarDecl: HeapVarDecl,
    Assignment: Assignment,
    IfGuard: IfGuard,
};

pub const Assignment = struct {
    target: *Expr,
    op: []const u8,
    value: *Expr,
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
    Number: i64,
    MethodCall: MethodCall,
    HeapLookup: HeapLookup,
    Dereference: *Expr,
};

pub const VarDecl = struct {
    name: []const u8,
    var_type: VarType,
    value: *Expr,
};

pub const VarType = enum {
    reg,
    imm,
};

pub const HeapLookup = struct {
    map_name: []const u8,
    key_expr: *Expr,
};

pub const MethodCall = struct {
    receiver: []const u8,
    method: []const u8,
    arg: *Expr,
};

pub const HeapVarDecl = struct {
    name: []const u8,
    lookup: HeapLookup,
};
