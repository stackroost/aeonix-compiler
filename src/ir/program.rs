use super::{UnitIr, LoweringError};
use crate::ast::Program;

#[derive(Debug, Clone)]
pub struct ProgramIr {
    pub units: Vec<UnitIr>,
}

pub fn lower_program(program: &Program) -> Result<ProgramIr, LoweringError> {
    let mut units = Vec::new();
    
    for unit in &program.units {
        units.push(UnitIr::lower(unit)?);
    }

    Ok(ProgramIr { units })
}