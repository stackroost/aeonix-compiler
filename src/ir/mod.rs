// src/ir/mod.rs
pub mod ir;
pub mod program;
pub mod unit;
pub mod instruction;

pub use instruction::{Instruction, BinaryOp, Operand};
pub use program::ProgramIr;
pub use unit::UnitIr;

/// Lowering errors
#[derive(Debug, thiserror::Error)]
pub enum LoweringError {
    #[error("Failed to lower unit: {0}")]
    UnitLowering(String),
    
    #[error("Invalid operand in expression")]
    InvalidOperand,
    
    #[error("Unknown map: {0}")]
    UnknownMap(String),
    
    #[error("Type mismatch")]
    TypeMismatch,
}