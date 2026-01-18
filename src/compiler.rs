use crate::parser;
use crate::source_manager::SourceManager;
use miette::{IntoDiagnostic, WrapErr, Report};
use std::fs;
use std::path::Path;

pub fn compile(input_path: &Path, output_path: &Path) -> Result<(), miette::Report> {
    match input_path.extension().and_then(|e| e.to_str()) {
        Some("snx") => {}
        _ => {
            return Err(miette::miette!(
                "Invalid source file extension. Expected a .snx file, got: {}",
                input_path.display()
            ));
        }
    }

    let src = fs::read_to_string(input_path)
        .into_diagnostic()
        .wrap_err(format!(
            "Failed to read input file: {}",
            input_path.display()
        ))?;

    if src.is_empty() {
        return Err(miette::miette!("Empty input source code"));
    }

    let mut sources = SourceManager::new();
    let _file_id = sources.add_file(input_path.display().to_string(), src.clone());

    let _program = match parser::parse(&src) {
        Ok(prog) => prog,
        Err(e) => {
            let report: Report = e.into();
            eprintln!("{:?}", report);
            return Err(report);
        }
    };

    fs::write(output_path, src)
        .into_diagnostic()
        .wrap_err("Failed to write output file")?;

    Ok(())
}
