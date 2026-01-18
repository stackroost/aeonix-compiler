use crate::parser::SourceLoc;

/// eBPF program unit (XDP, TC, tracepoint, cgroup, etc.)
#[derive(Debug, Clone)]
#[allow(unused)]
pub struct Unit {
    pub name: String,
    pub loc: SourceLoc,
    pub sections: Vec<String>,
    pub license: Option<String>,
    pub body: Vec<Stmt>,
}

/// Statement in an eBPF program body
#[derive(Debug, Clone)]
#[allow(unused)]
pub struct Stmt {
    pub kind: StmtKind,
    pub loc: SourceLoc,
}

#[derive(Debug, Clone)]
#[allow(unused)]
pub enum StmtKind {
    Return(Box<Expr>),
    VarDecl(VarDecl),
    HeapVarDecl(HeapVarDecl),
    Assignment(Assignment),
    IfGuard(IfGuard),
}

/// Variable assignment: `x = value` or `x += value`
#[derive(Debug, Clone)]
#[allow(unused)]
pub struct Assignment {
    pub target: Box<Expr>,
    pub op: AssignmentOp,
    pub value: Box<Expr>,
}

/// Assignment operators
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
#[allow(unused)]
pub enum AssignmentOp {
    Assign,      // =
    AddAssign,   // +=
    // Add more: SubAssign, MulAssign, etc. as needed
}

/// If-guard statement: `if (condition) { body }`
#[derive(Debug, Clone)]
#[allow(unused)]
pub struct IfGuard {
    pub condition: Expr,
    pub body: Vec<Stmt>,
}

/// Expression (produces a value)
#[derive(Debug, Clone)]
#[allow(unused)]
pub struct Expr {
    pub kind: ExprKind,
    pub loc: SourceLoc,
}

#[derive(Debug, Clone)]
#[allow(unused)]
pub enum ExprKind {
    Variable(String),
    Number(i64),
    MethodCall(MethodCall),
    HeapLookup(HeapLookup),
    Dereference(Box<Expr>),
}

/// Variable declaration: `reg x: u32 = value;` or `imm x: u32 = value;`
#[derive(Debug, Clone)]
#[allow(unused)]
pub struct VarDecl {
    pub name: String,
    pub var_type: VarType,
    pub value: Box<Expr>,
}

/// Variable storage class
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
#[allow(unused)]
pub enum VarType {
    Reg,  // Register variable
    Imm,  // Immediate/constant variable
}

/// Heap map lookup: `map[key]`
#[derive(Debug, Clone)]
#[allow(unused)]
pub struct HeapLookup {
    pub map_name: String,
    pub key_expr: Box<Expr>,
}

/// Method call: `receiver.method(arg)`
#[derive(Debug, Clone)]
#[allow(unused)]
pub struct MethodCall {
    pub receiver: String,
    pub method: String,
    pub arg: Box<Expr>,
}

/// Heap variable declaration: `heap h = map[key];`
#[derive(Debug, Clone)]
#[allow(unused)]
pub struct HeapVarDecl {
    pub name: String,
    pub lookup: HeapLookup,
}

