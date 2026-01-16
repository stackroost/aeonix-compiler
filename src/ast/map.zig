const SourceLoc = @import("../parser/token.zig").SourceLoc;

pub const MapDecl = struct {
    name: []const u8,
    map_type: MapType,
    key_type: Type,
    value_type: Type,
    max_entries: u32,
    loc: SourceLoc,
};

pub const MapType = enum {
    hash,
    array,
    ringbuf,
    lru_hash,
    prog_array,
    perf_event_array,
};

pub const Type = enum {
    u32,
    u64,
    i32,
    i64,
};
