const std = @import("std");
const ast = @import("../ast/unit.zig");
const Diagnostics = @import("../diagnostics.zig").Diagnostics;


pub const HeapSafetyState = enum {
    
    unchecked,
    
    verified,
};


pub const SymbolEntry = struct {
    name: []const u8,
    var_type: union(enum) {
        reg: void,
        imm: void,
        heap: HeapSafetyState,
    },
};


fn checkStmtSafety(stmt: *const ast.Stmt, symbols: *std.StringHashMap(SymbolEntry), diag: *Diagnostics) bool {
    switch (stmt.kind) {
        .Return => return true,
        .VarDecl => |vd| {
            
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
            
            const entry = SymbolEntry{
                .name = hvd.name,
                .var_type = .{ .heap = .unchecked },
            };
            symbols.put(hvd.name, entry) catch return false;
            return true;
        },
        .IfGuard => |guard| {
            
            if (!checkExprSafety(&guard.condition, symbols, diag)) {
                return false;
            }

            
            switch (guard.condition.kind) {
                .VarRef => |var_name| {
                    if (symbols.get(var_name)) |entry| {
                        switch (entry.var_type) {
                            .heap => {
                                
                                const verified_entry = SymbolEntry{
                                    .name = entry.name,
                                    .var_type = .{ .heap = .verified },
                                };
                                symbols.put(var_name, verified_entry) catch return false;
                            },
                            else => {
                                
                                return false;
                            },
                        }
                    } else {
                        
                        return false;
                    }
                },
                else => {
                    
                    return false;
                },
            }

            
            for (guard.body) |body_stmt| {
                if (!checkStmtSafety(&body_stmt, symbols, diag)) {
                    return false;
                }
            }
            return true;
        },
    }
}


fn checkExprSafety(expr: *const ast.Expr, symbols: *const std.StringHashMap(SymbolEntry), _: *Diagnostics) bool {
    switch (expr.kind) {
        .VarRef => return true, 
        .HeapLookup => return true, 
        .Dereference => |inner_expr| {
            
            switch (inner_expr.kind) {
                .VarRef => |var_name| {
                    if (symbols.get(var_name)) |entry| {
                        switch (entry.var_type) {
                            .heap => |state| {
                                if (state == .unchecked) {
                                    
                                    return false;
                                }
                            },
                            else => {
                                
                                return false;
                            },
                        }
                    } else {
                        
                        return false;
                    }
                },
                else => {
                    
                    return false;
                },
            }
            return true;
        },
    }
}

pub fn checkUnit(u: *const ast.Unit, diag: *Diagnostics) bool {
    
    if (u.sections.len == 0) {
        
        return false;
    }

    
    var returns: usize = 0;
    for (u.body) |stmt| {
        switch (stmt.kind) {
            .Return => returns += 1,
            else => {},
        }
    }

    if (returns != 1) {
        
        return false;
    }

    
    var symbols = std.StringHashMap(SymbolEntry).init(std.heap.page_allocator);
    defer symbols.deinit();

    
    for (u.body) |stmt| {
        if (!checkStmtSafety(&stmt, &symbols, diag)) {
            return false;
        }
    }

    return true;
}
