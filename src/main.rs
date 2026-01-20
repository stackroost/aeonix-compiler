mod compiler;
mod diagnostics;
mod source_manager;
mod parser;
mod ast;
mod lexer;
mod ir;

use compiler::compile;
use std::env;
use std::path::PathBuf;
mod emit;

fn main() {
    let args: Vec<String> = env::args().collect();

    if args.len() != 5 || args[1] != "compile" || args[3] != "-o" {
        eprintln!("Usage: solnixc compile <input.snx> -o <output.o>");
        std::process::exit(1);
    }

    let input_path = PathBuf::from(&args[2]);
    let output_path = PathBuf::from(&args[4]);
    
    // Check if input file exists before attempting compilation
    if !input_path.exists() {
        eprintln!("Error: Input file does not exist: {}", input_path.display());
        eprintln!("Please provide a valid .snx source file.");
        std::process::exit(1);
    }
    
    if let Err(e) = compile(&input_path, &output_path) {
        eprintln!("\nError: {e:?}");
        std::process::exit(1);
    }

    println!("Compilation successful: {}", output_path.display());
}
