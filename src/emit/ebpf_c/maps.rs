use std::fmt::Write;

use crate::emit::util::fmt_err;

pub fn emit_maps(out: &mut String, _maps: &[()]) -> Result<(), String> {
    writeln!(out, "struct {{").map_err(fmt_err)?;
    writeln!(out, "    __uint(type, BPF_MAP_TYPE_HASH);").map_err(fmt_err)?;
    writeln!(out, "    __uint(max_entries, 1024);").map_err(fmt_err)?;
    writeln!(out, "    __type(key, __u32);").map_err(fmt_err)?;
    writeln!(out, "    __type(value, __u64);").map_err(fmt_err)?;
    writeln!(out, "}} connection_counter SEC(\".maps\");").map_err(fmt_err)?;
    writeln!(out).map_err(fmt_err)?;
    Ok(())
}
