// src/ir/instruction.rs
use crate::ast::{Type, VarType};

/// Single Static Assignment (SSA) style instruction
#[derive(Debug, Clone)]
pub struct Instruction {
    pub result: VarId,
    pub opcode: Opcode,
    pub operands: Vec<Operand>,
    pub result_type: Type,
}

/// Variable identifier (virtual register)
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct VarId(pub u32);

/// Instruction opcodes for eBPF
#[derive(Debug, Clone)]
pub enum Opcode {
    // Memory operations
    LoadMap { map_name: String },
    LoadKey { offset: i32 },
    Store { size: u8 },
    
    // Arithmetic
    Binary { op: BinaryOp },
    Negate,
    
    // Control flow
    Return,
    JumpIf { condition: JumpCondition, target: BlockId },
    
    // Function calls
    CallHelper { func_id: u32 },
    CallMap { map_fd: i32 },
}

/// Binary operations
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BinaryOp {
    Add,
    Sub,
    Mul,
    Div,
    Mod,
    BitAnd,
    BitOr,
    BitXor,
    LShift,
    RShift,
    Eq,
    Neq,
    Lt,
    Gt,
    Le,
    Ge,
}

/// Jump conditions
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum JumpCondition {
    Equal,
    NotEqual,
    GreaterThan,
    LessThan,
    GreaterEqual,
    LessEqual,
}

/// Operand types
#[derive(Debug, Clone)]
pub enum Operand {
    Var(VarId),
    Immediate(i64),
    String(String),
}

impl Operand {
    pub fn is_register(&self) -> bool {
        matches!(self, Self::Var(_))
    }

    pub fn is_immediate(&self) -> bool {
        matches!(self, Self::Immediate(_))
    }
}