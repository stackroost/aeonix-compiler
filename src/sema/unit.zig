const std = @import("std");
const ast = @import("../ast/unit.zig");
const Diagnostics = @import("../diagnostics.zig").Diagnostics;

/// Safety state for heap variables
pub const HeapSafetyState = enum {
    /// Heap variable that has not been verified with guard()
    unchecked,
    /// Heap variable that has been verified with guard()
    verified,
};

/// Symbol table entry for variables
pub const SymbolEntry = struct {
    name: []const u8,
    var_type: union(enum) {
        reg: void,
        imm: void,
        heap: HeapSafetyState,
    },
};

/// Check heap variable safety in statements
fn checkStmtSafety(stmt: *const ast.Stmt, symbols: *std.StringHashMap(SymbolEntry), diag: *Diagnostics) bool {
    switch (stmt.kind) {
        .Return => return true,
        .VarDecl => |vd| {
            // Add variable to symbol table
            const entry = SymbolEntry{
                .name = vd.name,
                .var_type = switch (vd.var_type) {
                    .reg => .reg,
                    .imm => .imm,
                },
            };
            symbols.put(vd.name, entry) catch return false;
            return true;
        },
        .HeapVarDecl => |hvd| {
            // Add heap variable as unchecked to symbol table
            const entry = SymbolEntry{
                .name = hvd.name,
                .var_type = .{ .heap = .unchecked },
            };
            symbols.put(hvd.name, entry) catch return false;
            return true;
        },
        .IfGuard => |guard| {
            // Check the condition expression for safety
            if (!checkExprSafety(&guard.condition, symbols, diag)) {
                return false;
            }

            // Check the condition - should be a variable reference to a heap variable
            switch (guard.condition.kind) {
                .VarRef => |var_name| {
                    if (symbols.get(var_name)) |entry| {
                        switch (entry.var_type) {
                            .heap => {
                                // Mark this heap variable as verified
                                const verified_entry = SymbolEntry{
                                    .name = entry.name,
                                    .var_type = .{ .heap = .verified },
                                };
                                symbols.put(var_name, verified_entry) catch return false;
                            },
                            else => {
                                // TODO: Add proper location for error
                                return false;
                            },
                        }
                    } else {
                        // TODO: Report error for undefined variable
                        return false;
                    }
                },
                else => {
                    // TODO: Report error for invalid guard condition
                    return false;
                },
            }

            // Recursively check statements in the guard body
            for (guard.body) |body_stmt| {
                if (!checkStmtSafety(&body_stmt, symbols, diag)) {
                    return false;
                }
            }
            return true;
        },
    }
}

/// Check for unsafe heap dereferences in expressions
fn checkExprSafety(expr: *const ast.Expr, symbols: *const std.StringHashMap(SymbolEntry), _: *Diagnostics) bool {
    switch (expr.kind) {
        .VarRef => return true, // Variable references are always safe
        .HeapLookup => return true, // Heap lookups are safe (they create unchecked heap vars)
        .Dereference => |inner_expr| {
            // Check if we're dereferencing a verified heap variable
            switch (inner_expr.kind) {
                .VarRef => |var_name| {
                    if (symbols.get(var_name)) |entry| {
                        switch (entry.var_type) {
                            .heap => |state| {
                                if (state == .unchecked) {
                                    // TODO: Report error for dereferencing unchecked heap variable
                                    return false;
                                }
                            },
                            else => {
                                // TODO: Report error for dereferencing non-heap variable
                                return false;
                            },
                        }
                    } else {
                        // TODO: Report error for undefined variable
                        return false;
                    }
                },
                else => {
                    // TODO: Report error for invalid dereference target
                    return false;
                },
            }
            return true;
        },
    }
}

pub fn checkUnit(u: *const ast.Unit, diag: *Diagnostics) bool {
    // section required
    if (u.sections.len == 0) {
        // TODO: Report error for missing sections
        return false;
    }

    // exactly one return
    var returns: usize = 0;
    for (u.body) |stmt| {
        switch (stmt.kind) {
            .Return => returns += 1,
            else => {},
        }
    }

    if (returns != 1) {
        // TODO: Report error for wrong number of returns
        return false;
    }

    // Heap variable safety checking
    var symbols = std.StringHashMap(SymbolEntry).init(std.heap.page_allocator);
    defer symbols.deinit();

    // Check all statements for heap safety
    for (u.body) |stmt| {
        if (!checkStmtSafety(&stmt, &symbols, diag)) {
            return false;
        }
    }

    return true;
}
