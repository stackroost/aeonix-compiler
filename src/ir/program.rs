// src/ir/program.rs
use super::{UnitIr, LoweringError};
use crate::ast::Program;

/// IR for entire Solnix program
#[derive(Debug, Clone)]
pub struct ProgramIr {
    pub units: Vec<UnitIr>,
    pub maps: Vec<LoweredMap>,
}

/// Map info needed for code generation
#[derive(Debug, Clone)]
pub struct LoweredMap {
    pub name: String,
    pub map_type: crate::ast::MapType,
    pub fd: i32, // File descriptor placeholder
}

/// Lower AST Program to IR
pub fn lower_program(program: &Program) -> Result<ProgramIr, LoweringError> {
    let mut units = Vec::new();
    let mut maps = Vec::new();

    // Lower maps first (they become global resources)
    for map_decl in &program.maps {
        maps.push(LoweredMap {
            name: map_decl.name.clone(),
            map_type: map_decl.map_type,
            fd: -1, // Will be resolved during codegen
        });
    }

    // Lower each unit
    for unit in &program.units {
        units.push(UnitIr::lower(unit)?);
    }

    Ok(ProgramIr { units, maps })
}