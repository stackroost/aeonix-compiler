use std::path::PathBuf;

fn main() {
    let llvm_config = std::env::var("LLVM_SYS_210_PREFIX")
        .map(PathBuf::from)
        .unwrap_or_else(|_| PathBuf::from("/usr/lib/llvm-21"));

    let llvm_include = llvm_config.join("include");
    let llvm_lib     = llvm_config.join("lib");

    println!("cargo:rustc-env=LLVM_SYS_210_PREFIX={}", llvm_config.display());
    
    println!("cargo:rustc-link-search=native={}", llvm_lib.display());
    println!("cargo:rustc-link-lib=dylib=LLVM-21");
    println!("cargo:rustc-link-arg=-Wl,-rpath,{}", llvm_lib.display());
    
    println!("cargo:rerun-if-changed=build.rs");
}