// src/ast/program.rs
use super::{MapDecl, Unit};

/// Root AST node representing a complete Solnix source file
#[derive(Debug, Clone)]
#[allow(unused)]
pub struct Program {
    pub maps: Vec<MapDecl>,
    pub units: Vec<Unit>,
}