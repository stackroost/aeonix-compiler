// src/ast/mod.rs
pub mod program;
pub mod map;
pub mod unit;

// Re-export everything at the crate root for convenient imports
pub use program::Program;
pub use map::{MapDecl, MapType, Type};
pub use unit::{
    Assignment, AssignmentOp, Expr, ExprKind, HeapLookup, HeapVarDecl,
    IfGuard, MethodCall, Stmt, StmtKind, Unit, VarDecl, VarType,
};