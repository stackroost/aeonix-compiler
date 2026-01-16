const std = @import("std");
const ast = @import("../ast/mod.zig");
const Diagnostics = @import("../diagnostics.zig").Diagnostics;

const UnitSema = @import("unit.zig");
const MapSema = @import("map.zig");

pub const ValidationError = error{
    UnitError,
    MapError,
};

pub fn checkProgram(program: *const ast.Program, diagnostics: *Diagnostics, source: []const u8) !void {
    var map_names = std.StringHashMap(void).init(diagnostics.allocator);
    defer map_names.deinit();

    for (program.maps) |map_decl| {
        MapSema.checkMap(&map_decl, diagnostics, source, &map_names) catch |err| {
            _ = err;
            return ValidationError.MapError;
        };
    }

    for (program.units) |unit_decl| {
        UnitSema.checkUnit(&unit_decl, diagnostics, source) catch |err| {
            _ = err;
            return ValidationError.UnitError;
        };
    }
}
