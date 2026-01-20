use std::fmt::Write;
use std::path::Path;

use crate::ir::ProgramIr;

use super::{helpers, maps, write, xdp};

pub fn emit_program(program: &ProgramIr, output: &Path) -> Result<(), String> {
    let mut c = String::new();

    emit_prelude(&mut c)?;
    helpers::emit_helpers(&mut c)?;
    maps::emit_maps(&mut c, &[])?;

    for unit in &program.units {
        match unit.sections.get(0).map(|s| s.as_str()).unwrap_or("unknown") {
            "xdp" => xdp::emit_xdp(&mut c, unit)?,
            s => return Err(format!("Unsupported section: {}", s)),
        }
    }

    write::compile_to_object(&c, output)?;
    Ok(())
}

fn emit_prelude(out: &mut String) -> Result<(), String> {
    // CO-RE/libbpf standard headers
    writeln!(out, "#include \"vmlinux.h\"").map_err(err)?;
    writeln!(out, "#include <bpf/bpf_helpers.h>").map_err(err)?;
    writeln!(out, "#include <bpf/bpf_endian.h>").map_err(err)?;
    writeln!(out).map_err(err)?;

    // XDP return codes (usually in linux/bpf.h; define to avoid extra headers)
    writeln!(out, "#ifndef XDP_ABORTED").map_err(err)?;
    writeln!(out, "#define XDP_ABORTED 0").map_err(err)?;
    writeln!(out, "#define XDP_DROP 1").map_err(err)?;
    writeln!(out, "#define XDP_PASS 2").map_err(err)?;
    writeln!(out, "#define XDP_TX 3").map_err(err)?;
    writeln!(out, "#define XDP_REDIRECT 4").map_err(err)?;
    writeln!(out, "#endif").map_err(err)?;
    writeln!(out).map_err(err)?;

    Ok(())
}

fn err(e: std::fmt::Error) -> String {
    e.to_string()
}
