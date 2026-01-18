// src/ir/unit.rs
use super::{Instruction, VarId, BlockId};
use crate::ast::{Unit, Stmt, Expr, StmtKind, ExprKind, VarType};
use crate::ir::{LoweringError, Opcode, BinaryOp, Operand, JumpCondition};
use std::collections::HashMap;

/// IR for a single eBPF program unit
#[derive(Debug, Clone)]
pub struct UnitIr {
    pub name: String,
    pub sections: Vec<String>,
    pub license: String,
    pub entry_block: BlockId,
    pub blocks: Vec<BasicBlock>,
    pub next_var_id: u32,
}

/// Basic block for control flow
#[derive(Debug, Clone)]
pub struct BasicBlock {
    pub id: BlockId,
    pub instructions: Vec<Instruction>,
    pub terminator: Terminator,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct BlockId(pub u32);

/// Block terminator (control flow)
#[derive(Debug, Clone)]
pub enum Terminator {
    Return(Operand),
    Jump(BlockId),
    Branch { condition: Operand, true_block: BlockId, false_block: BlockId },
}

impl UnitIr {
    /// Create new UnitIr from AST Unit
    pub fn lower(unit: &Unit) -> Result<Self, LoweringError> {
        let mut ir = Self {
            name: unit.name.clone(),
            sections: unit.sections.clone(),
            license: unit.license.clone().unwrap_or_else(|| "GPL".to_string()),
            entry_block: BlockId(0),
            blocks: Vec::new(),
            next_var_id: 0,
        };

        // Create entry block
        let mut current_block = BasicBlock {
            id: BlockId(0),
            instructions: Vec::new(),
            terminator: Terminator::Jump(BlockId(1)), // dummy
        };

        // Lower each statement
        for stmt in &unit.body {
            lower_statement(stmt, &mut ir, &mut current_block)?;
        }

        ir.blocks.push(current_block);
        Ok(ir)
    }

    fn alloc_var(&mut self, var_type: crate::ast::Type) -> VarId {
        let id = VarId(self.next_var_id);
        self.next_var_id += 1;
        id
    }
}

/// Lower a single statement to IR instructions
fn lower_statement(
    stmt: &Stmt,
    ir: &mut UnitIr,
    block: &mut BasicBlock,
) -> Result<(), LoweringError> {
    match &stmt.kind {
        StmtKind::VarDecl(var_decl) => {
            // Allocate virtual register
            let var_id = ir.alloc_var(var_decl.var_type.into());
            let value = lower_expr(&var_decl.value, ir, block)?;
            
            // Store value in virtual register
            block.instructions.push(Instruction {
                result: var_id,
                opcode: Opcode::Binary { op: BinaryOp::Add }, // NOP for now
                operands: vec![value, Operand::Immediate(0)],
                result_type: var_decl.var_type.into(),
            });
        }
        
        StmtKind::Return(expr) => {
            let ret_value = lower_expr(expr, ir, block)?;
            block.terminator = Terminator::Return(ret_value);
        }
        
        StmtKind::Assignment(assign) => {
            let target = lower_expr(&assign.target, ir, block)?;
            let value = lower_expr(&assign.value, ir, block)?;
            // TODO: Handle different assignment ops
        }
        
        StmtKind::IfGuard(if_guard) => {
            // Lower condition
            let condition = lower_expr(&if_guard.condition, ir, block)?;
            
            // Create true and false blocks
            let true_block = BlockId(ir.blocks.len() as u32);
            let false_block = BlockId(ir.blocks.len() as u32 + 1);
            
            // Set current block terminator
            block.terminator = Terminator::Branch {
                condition,
                true_block,
                false_block,
            };
            
            // TODO: Lower true block body
        }
        
        _ => return Err(LoweringError::UnitLowering("Unsupported statement".to_string())),
    }
    Ok(())
}

/// Lower expression to IR operand
fn lower_expr(
    expr: &Expr,
    ir: &mut UnitIr,
    block: &mut BasicBlock,
) -> Result<Operand, LoweringError> {
    match &expr.kind {
        ExprKind::Variable(name) => {
            // TODO: Look up variable in symbol table
            Ok(Operand::String(name.clone()))
        }
        
        ExprKind::Number(n) => {
            Ok(Operand::Immediate(*n))
        }
        
        ExprKind::MethodCall(call) => {
            // e.g., map.lookup(key)
            if call.method == "lookup" {
                let map_fd = Operand::String(call.receiver.clone());
                let key = lower_expr(&call.arg, ir, block)?;
                let result = ir.alloc_var(crate::ast::Type::U64);
                
                block.instructions.push(Instruction {
                    result,
                    opcode: Opcode::CallMap { map_fd: -1 }, // TODO: Resolve FD
                    operands: vec![key],
                    result_type: crate::ast::Type::U64,
                });
                
                Ok(Operand::Var(result))
            } else {
                Err(LoweringError::InvalidOperand)
            }
        }
        
        _ => Err(LoweringError::InvalidOperand),
    }
}