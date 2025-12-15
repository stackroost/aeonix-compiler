# aeonix-compiler

A compiler for the Aeonix programming language, written in Zig. Supports compilation to eBPF and x86_64 targets.

## Building

```bash
zig build
```

## Usage

```bash
./zig-out/bin/aeonix [command] [file]
```

Commands:
- `build <file.aex>`: Compile Aeonix source
- `run <file.aex>`: Compile and execute
- `check <file.aex>`: Syntax and verifier checks
- `ir <file.aex>`: Emit intermediate representation
- `help`: Show command help
