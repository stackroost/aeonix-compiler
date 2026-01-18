// src/ast/map.rs
use crate::parser::SourceLoc;

/// eBPF map declaration (hash, array, ringbuf, etc.)
#[derive(Debug, Clone)]
#[allow(unused)]
pub struct MapDecl {
    pub name: String,
    pub map_type: MapType,
    pub key_type: Type,
    pub value_type: Type,
    pub max_entries: u32,
    pub loc: SourceLoc,
}

/// eBPF map types
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
#[allow(unused)]
pub enum MapType {
    Hash,
    Array,
    Ringbuf,
    LruHash,
    ProgArray,
    PerfEventArray,
}

/// Primitive types for eBPF registers and immediates
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Type {
    U32,
    U64,
    I32,
    I64,
}