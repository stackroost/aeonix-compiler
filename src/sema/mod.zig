const std = @import("std");
const ast = @import("../ast/unit.zig");
const Diagnostics = @import("../diagnostics.zig").Diagnostics;
const SectionValidator = @import("section.zig").SectionValidator;

pub const ValidationError = error{
    EmptyUnitName,
    NoSections,
    InvalidSection,
    MissingLicense,
    InvalidLicense,
    NoReturnOrInstructions,
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

    // Validate section names - invalid sections will cause load-time failures
    for (unit.sections) |section| {
        if (!SectionValidator.isValid(section)) {
            const msg = try std.fmt.allocPrint(
                diagnostics.allocator,
                "Invalid section name: '{s}'. Invalid section names will cause the program to fail at load time.",
                .{section},
            );
            try diagnostics.reportError(msg, unit.loc, source);
            diagnostics.allocator.free(msg); // reportError now owns a copy
            return ValidationError.InvalidSection;
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
        try diagnostics.reportWarning(msg, unit.loc, source);
        diagnostics.allocator.free(msg); // reportWarning now owns a copy
    }

    // Validate that unit has at least one return statement or instruction
    if (unit.body.len == 0) {
        try diagnostics.reportError("Unit must have at least one return statement or instruction", unit.loc, source);
        return ValidationError.NoReturnOrInstructions;
    }
}
