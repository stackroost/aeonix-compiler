const std = @import("std");
const SourceLoc = @import("parser/token.zig").SourceLoc;

pub const DiagnosticLevel = enum {
    @"error",
    warning,
};

pub const Diagnostic = struct {
    level: DiagnosticLevel,
    message: []const u8,
    loc: SourceLoc,
    source: []const u8, // Full source code for context

    pub fn format(
        self: Diagnostic,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        const level_str = switch (self.level) {
            .@"error" => "error",
            .warning => "warning",
        };

        try writer.print("{s}: {s}\n", .{ level_str, self.message });

        // Find the line containing the error
        var line_start: usize = 0;
        var line_num: usize = 1;
        var i: usize = 0;

        while (i < self.loc.offset and i < self.source.len) {
            if (self.source[i] == '\n') {
                line_num += 1;
                line_start = i + 1;
            }
            i += 1;
        }

        // Find line end
        var line_end = line_start;
        while (line_end < self.source.len and self.source[line_end] != '\n') {
            line_end += 1;
        }

        const line = self.source[line_start..line_end];
        const column_in_line = self.loc.offset - line_start;

        // Print line number and source line
        try writer.print("  {d} | {s}\n", .{ line_num, line });

        // Print caret pointing to error
        const padding = "     | ";
        try writer.print("{s}", .{padding});
        var j: usize = 0;
        while (j < column_in_line) : (j += 1) {
            try writer.writeByte(' ');
        }
        try writer.print("^\n", .{});
    }
};

pub const Diagnostics = struct {
    allocator: std.mem.Allocator,
    diagnostics: std.ArrayList(Diagnostic),

    pub fn init(allocator: std.mem.Allocator) Diagnostics {
        return .{
            .allocator = allocator,
            .diagnostics = std.ArrayList(Diagnostic).initCapacity(allocator, 16) catch {
                @panic("Failed to allocate diagnostics");
            },
        };
    }

    pub fn deinit(self: *Diagnostics) void {
        self.diagnostics.deinit(self.allocator);
    }

    pub fn reportError(
        self: *Diagnostics,
        message: []const u8,
        loc: SourceLoc,
        source: []const u8,
    ) !void {
        try self.diagnostics.append(self.allocator, Diagnostic{
            .level = .@"error",
            .message = message,
            .loc = loc,
            .source = source,
        });
    }

    pub fn reportWarning(
        self: *Diagnostics,
        message: []const u8,
        loc: SourceLoc,
        source: []const u8,
    ) !void {
        try self.diagnostics.append(self.allocator, Diagnostic{
            .level = .warning,
            .message = message,
            .loc = loc,
            .source = source,
        });
    }

    pub fn hasErrors(self: *const Diagnostics) bool {
        for (self.diagnostics.items) |diag| {
            if (diag.level == .@"error") {
                return true;
            }
        }
        return false;
    }

    pub fn printAll(self: *const Diagnostics, writer: anytype) !void {
        for (self.diagnostics.items) |diag| {
            try diag.format("", .{}, writer);
        }
    }

    const StdDebugWriter = struct {};

    pub fn print(self: *StdDebugWriter, comptime fmt: []const u8, args: anytype) !void {
        _ = fmt;
        _ = args;
        std.debug.print(fmt, args);
    }

    pub fn writeByte(self: *StdDebugWriter, b: u8) !void {
        _ = b;
        var buf: [1]u8 = .{b};
        std.debug.print("{s}", .{buf[0..]});
    }

    pub fn printAllStd(self: *const Diagnostics) !void {
        var w = StdDebugWriter{};
        try self.printAll(&w);
    }
};
