pub const Program = struct {
    units: []Unit,
};

pub const Unit = struct {
    name: []const u8,
    section: []const u8,
    body: []Stmt,
};

pub const Stmt = union(enum) {
    Return: i64,
    Guard: GuardStmt,
};

pub const GuardStmt = struct {
    cond: Expr,
    then_body: []Stmt,
    else_body: ?[]Stmt,
};

pub const Expr = union(enum) {
    Int: i64,
    Eq: struct { lhs: *Expr, rhs: *Expr },
};
