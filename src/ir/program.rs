use super::{UnitIr, LoweringError};
use crate::ast::{MapDecl, Program};

#[derive(Debug, Clone)]
pub struct ProgramIr {
    pub maps: Vec<MapDecl>,
    pub units: Vec<UnitIr>,
}

pub fn lower_program(program: &Program) -> Result<ProgramIr, LoweringError> {
    let mut units = Vec::new();

    for unit in &program.units {
        units.push(UnitIr::lower(unit)?);
    }

    Ok(ProgramIr {
        maps: program.maps.clone(),
        units,
    })
}
