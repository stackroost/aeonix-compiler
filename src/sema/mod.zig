const std = @import("std");
const ast = @import("../ast/unit.zig");
const Diagnostics = @import("../diagnostics.zig").Diagnostics;

pub const ValidationError = error{
    EmptyUnitName,
    NoSections,
    MissingLicense,
    InvalidLicense,
};

pub fn checkUnit(unit: *const ast.Unit, diagnostics: *Diagnostics, source: []const u8) !void {
    // Validate unit name
    if (unit.name.len == 0) {
        try diagnostics.reportError("Unit name cannot be empty", unit.loc, source);
        return ValidationError.EmptyUnitName;
    }

    // Validate at least one section
    if (unit.sections.len == 0) {
        try diagnostics.reportError("Unit must have at least one section", unit.loc, source);
        return ValidationError.NoSections;
    }

    // Validate section names (warn about unknown sections)
    const valid_sections = [_][]const u8{ "xdp", "tc", "kprobe", "uprobe", "tracepoint", "socket", "cgroup" };
    for (unit.sections) |section| {
        var found = false;
        for (valid_sections) |valid| {
            if (std.mem.startsWith(u8, section, valid)) {
                found = true;
                break;
            }
        }
        if (!found) {
            try diagnostics.reportWarning(
                try std.fmt.allocPrint(diagnostics.allocator, "Unknown section name: '{s}'", .{section}),
                unit.loc,
                source,
            );
        }
    }

    // Validate license is provided
    if (unit.license == null) {
        try diagnostics.reportError("License is required for eBPF programs", unit.loc, source);
        return ValidationError.MissingLicense;
    }

    // Validate license is valid
    const license = unit.license.?;
    const valid_licenses = [_][]const u8{ "GPL", "Dual BSD/GPL", "GPL v2", "GPL-2.0" };
    var license_valid = false;
    for (valid_licenses) |valid| {
        if (std.mem.eql(u8, license, valid)) {
            license_valid = true;
            break;
        }
    }
    if (!license_valid) {
        const msg = try std.fmt.allocPrint(diagnostics.allocator, "Unknown license: '{s}'", .{license});
        defer diagnostics.allocator.free(msg);
        try diagnostics.reportWarning(msg, unit.loc, source);
    }
}
