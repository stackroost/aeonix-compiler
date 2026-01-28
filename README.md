# Solnix Compiler  

A simple compiler for the Solnix programming language. Solnix lets you write eBPF (Extended Berkeley Packet Filter) programs in a high-level, readable syntax instead of low-level C code.

## What is Solnix?

Solnix is a domain-specific language for creating eBPF programs. It provides a cleaner way to define maps, packet filters, and network functions that run in the Linux kernel.

## 🚧 Status: Under Active Development

## Installation

Make sure you have Rust installed. Then:

```bash
cargo build --release
```

This will create the `solnixc` binary in `target/release/`.

## Usage

Compile a `.snx` source file to an eBPF object file:

```bash
./solnixc compile input.snx -o output.o
```

## Example

Here's a simple Solnix program that counts connections by source IP:

```solnix
map connection_counter {
    type: .hash;
    key: u32;
    value: u64;
    max: 1024;
}

unit filter_packets {
    section: "xdp";
    license: "GPL";

    reg src_ip = ctx.load_u32(26);
    heap count_ptr = connection_counter.lookup(src_ip);

    if guard(count_ptr) {
        *count_ptr += 1;
    }
    
    return 1;
}
```

Save this as `example.snx` and compile it with:

```bash
./solnixc compile example.snx -o example.o
```

## Features

- High-level syntax for eBPF development
- Automatic code generation to eBPF C
- Support for XDP (eXpress Data Path) programs
- Hash maps and other eBPF data structures

## License

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

