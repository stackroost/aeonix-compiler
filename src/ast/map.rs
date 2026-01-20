
use crate::parser::SourceLoc;

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

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Type {
    U32,
    U64,
    I32,
    I64,
}