# solnix-compiler

A compiler for the solnix programming language, written in Zig. Supports compilation to eBPF and x86_64 targets.

## Building

```bash
zig build
```

## Usage

```bash
./zig-out/bin/solnix [command] [file]
```

Commands:
- `build <file.snx>`: Compile Aeonix source
- `run <file.snx>`: Compile and execute
- `check <file.snx>`: Syntax and verifier checks
- `ir <file.snx>`: Emit intermediate representation
- `help`: Show command help
