const MapDecl = @import("map.zig").MapDecl;
const Unit = @import("unit.zig").Unit;

pub const Program = struct {
    maps: []MapDecl,
    units: []Unit,
};
