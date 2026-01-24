use std::fmt::Write;

use crate::ast::{MapDecl, MapType, Type};
use crate::emit::util::fmt_err;

pub fn emit_maps(out: &mut String, maps: &[MapDecl]) -> Result<(), String> {
    for m in maps {
        let bpf_map_type = map_type_to_c(m.map_type);
        let key_ty = type_to_c(m.key_type);
        let val_ty = type_to_c(m.value_type);
        
        let name = sanitize_ident(&m.name);

        writeln!(out, "struct {{").map_err(fmt_err)?;
        writeln!(out, "    __uint(type, {});", bpf_map_type).map_err(fmt_err)?;
        writeln!(out, "    __uint(max_entries, {});", m.max_entries).map_err(fmt_err)?;
        
        if m.map_type != MapType::Ringbuf {
            writeln!(out, "    __type(key, {});", key_ty).map_err(fmt_err)?;
            writeln!(out, "    __type(value, {});", val_ty).map_err(fmt_err)?;
        } else {
        }

        writeln!(out, "}} {} SEC(\".maps\");", name).map_err(fmt_err)?;
        writeln!(out).map_err(fmt_err)?;
    }

    Ok(())
}

fn map_type_to_c(t: MapType) -> &'static str {
    match t {
        MapType::Hash => "BPF_MAP_TYPE_HASH",
        MapType::Array => "BPF_MAP_TYPE_ARRAY",
        MapType::Ringbuf => "BPF_MAP_TYPE_RINGBUF",
        MapType::LruHash => "BPF_MAP_TYPE_LRU_HASH",
        MapType::ProgArray => "BPF_MAP_TYPE_PROG_ARRAY",
        MapType::PerfEventArray => "BPF_MAP_TYPE_PERF_EVENT_ARRAY",
    }
}

fn type_to_c(t: Type) -> &'static str {
    match t {
        Type::U32 => "__u32",
        Type::U64 => "__u64",
        Type::I32 => "__s32",
        Type::I64 => "__s64",
    }
}

fn sanitize_ident(name: &str) -> String {
    let mut out = String::with_capacity(name.len());
    for (i, ch) in name.chars().enumerate() {
        if (i == 0 && (ch.is_ascii_alphabetic() || ch == '_'))
            || (i != 0 && (ch.is_ascii_alphanumeric() || ch == '_'))
        {
            out.push(ch);
        } else if ch.is_ascii_alphanumeric() {
            if i == 0 {
                out.push('_');
            }
            out.push(ch);
        } else {
            out.push('_');
        }
    }
    if out.is_empty() {
        "_map".to_string()
    } else {
        out
    }
}
