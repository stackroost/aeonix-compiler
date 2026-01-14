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
    if (unit.name.len == 0) {
        try diagnostics.reportError("Unit name cannot be empty", unit.loc, source);
        return ValidationError.EmptyUnitName;
    }

    
    if (unit.sections.len == 0) {
        try diagnostics.reportError("Unit must have at least one section", unit.loc, source);
        return ValidationError.NoSections;
    }

    
    for (unit.sections) |section| {
        if (!SectionValidator.isValid(section)) {
            const msg = try std.fmt.allocPrint(
                diagnostics.allocator,
                "Invalid section name: '{s}'. Invalid section names will cause the program to fail at load time.",
                .{section},
            );
            try diagnostics.reportError(msg, unit.loc, source);
            diagnostics.allocator.free(msg); 
            return ValidationError.InvalidSection;
        }
    }

    
    if (unit.license == null) {
        try diagnostics.reportError("License is required for eBPF programs", unit.loc, source);
        return ValidationError.MissingLicense;
    }

    
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
        diagnostics.allocator.free(msg); 
    }

    
    if (unit.body.len == 0) {
        try diagnostics.reportError("Unit must have at least one return statement or instruction", unit.loc, source);
        return ValidationError.NoReturnOrInstructions;
    }

    
    const unit_sema = @import("unit.zig");
    _ = unit_sema.checkUnit(unit, diagnostics);
}
