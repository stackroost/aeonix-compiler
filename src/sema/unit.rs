
use crate::ast::Unit;
use crate::diagnostics::{DiagnosticReporter, Severity};
use crate::sema::SectionValidator;

#[derive(Debug, thiserror::Error)]
pub enum UnitValidationError {
    #[error("Unit name cannot be empty")]
    EmptyUnitName,
    
    #[error("Unit must have at least one section")]
    NoSections,
    
    #[error("Invalid section name")]
    InvalidSection,
    
    #[error("License is required for eBPF programs")]
    MissingLicense,
    
    #[error("Unit must have at least one return statement or instruction")]
    NoReturnOrInstructions,
}

pub fn check_unit(
    unit: &Unit,
    diagnostics: &mut DiagnosticReporter,
) -> Result<(), UnitValidationError> {
    if unit.name.is_empty() {
        diagnostics.report_error("Unit name cannot be empty", unit.loc);
        return Err(UnitValidationError::EmptyUnitName);
    }

    if unit.sections.is_empty() {
        diagnostics.report_error("Unit must have at least one section", unit.loc);
        return Err(UnitValidationError::NoSections);
    }

    for section in &unit.sections {
        if !SectionValidator::is_valid(section) {
            diagnostics.report_error(
                format!("Invalid section name: '{}'", section),
                unit.loc,
            );
            return Err(UnitValidationError::InvalidSection);
        }
    }

    let license = unit.license.as_deref().ok_or_else(|| {
        diagnostics.report_error("License is required for eBPF programs", unit.loc);
        UnitValidationError::MissingLicense
    })?;

    let valid_licenses = ["GPL", "Dual BSD/GPL", "GPL v2", "GPL-2.0"];
    if !valid_licenses.contains(&license) {
        diagnostics.report_warning(
            format!("Unknown license: '{}'. Recommended: GPL", license),
            unit.loc,
        );
    }

    if unit.body.is_empty() {
        diagnostics.report_error(
            "Unit must have at least one return statement or instruction",
            unit.loc,
        );
        return Err(UnitValidationError::NoReturnOrInstructions);
    }

    Ok(())
}