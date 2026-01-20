use std::{fs, path::Path, process::Command};

pub fn compile_to_object(code: &str, out: &Path) -> Result<(), String> {
    let c = out.with_extension("bpf.c");
    fs::write(&c, code).map_err(|e| e.to_string())?;
    
    let status = Command::new("clang")
        .args([
            "-O2",
            "-g",
            "-target", "bpf",
            "-D__TARGET_ARCH_x86",
            "-I.",
            "-c",
            c.to_str().unwrap(),
            "-o",
            out.to_str().unwrap(),
        ])
        .status()
        .map_err(|e| format!("failed to run clang: {e}"))?;

    if !status.success() {
        return Err("clang failed".into());
    }

    Ok(())
}
