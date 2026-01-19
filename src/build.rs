use std::process::Command;

fn main() {
    let llvm_include = Command::new("llvm-config-21")
        .arg("--includedir")
        .output()
        .unwrap();
    let llvm_include = String::from_utf8(llvm_include.stdout).unwrap();

    let out = Command::new("bindgen")
        .arg(format!("{}/llvm-c/Core.h", llvm_include.trim()))
        .arg(format!("{}/llvm-c/Target.h", llvm_include.trim()))
        .arg(format!("{}/llvm-c/TargetMachine.h", llvm_include.trim()))
        .arg("--allowlist-function")
        .arg("LLVM.*")
        .arg("-o")
        .arg("src/llvm.rs")
        .output()
        .unwrap();

    if !out.status.success() {
        panic!("bindgen failed");
    }
}
