const std = @import("std");
const ast = @import("../ast/map.zig");
const Diagnostics = @import("../diagnostics.zig").Diagnostics;

pub const ValidationError = error{
    MissingField,
    DuplicateMapName,
    InvalidType,
    InvalidKeyValueType,
    InvalidMaxEntries,
};

pub fn checkMap(
    map_decl: *const ast.MapDecl,
    diagnostics: *Diagnostics,
    source: []const u8,
    map_names: *std.StringHashMap(void),
) !void {
    if (map_names.get(map_decl.name) != null) {
        try diagnostics.reportError(
            "Duplicate map name",
            map_decl.loc,
            source,
        );
        return ValidationError.DuplicateMapName;
    }
    try map_names.put(map_decl.name, {});
    if (map_decl.max_entries == 0) {
        try diagnostics.reportError("Map 'max' must be greater than zero", map_decl.loc, source);
        return ValidationError.InvalidMaxEntries;
    }
    switch (map_decl.key_type) {
        .u32, .u64, .i32, .i64 => {},
        else => {
            try diagnostics.reportError("Invalid map key type", map_decl.loc, source);
            return ValidationError.InvalidKeyValueType;
        },
    }

    switch (map_decl.value_type) {
        .u32, .u64, .i32, .i64 => {},
        else => {
            try diagnostics.reportError("Invalid map value type", map_decl.loc, source);
            return ValidationError.InvalidKeyValueType;
        },
    }

    switch (map_decl.map_type) {
        .hash, .array, .ringbuf, .lru_hash, .prog_array => {},
        else => {
            try diagnostics.reportError("Invalid map type", map_decl.loc, source);
            return ValidationError.InvalidType;
        },
    }
}
