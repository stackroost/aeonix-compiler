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
    source: []const u8,

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

        var line_start: usize = 0;
        var line_num: usize = 1;
        var i: usize = 0;

        while (i < self.loc.offset and i < self.source.len) : (i += 1) {
            if (self.source[i] == '\n') {
                line_num += 1;
                line_start = i + 1;
            }
        }

        var line_end = line_start;
        while (line_end < self.source.len and self.source[line_end] != '\n') {
            line_end += 1;
        }

        const line = self.source[line_start..line_end];
        const column = self.loc.offset - line_start;

        try writer.print("  {d} | {s}\n", .{ line_num, line });
        try writer.print("     | ", .{});

        var j: usize = 0;
        while (j < column) : (j += 1) {
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
            .diagnostics = std.ArrayList(Diagnostic).initCapacity(
                allocator,
                16,
            ) catch @panic("OOM"),
        };
    }

    pub fn deinit(self: *Diagnostics) void {
        // Free all owned message strings
        for (self.diagnostics.items) |diag| {
            self.allocator.free(diag.message);
        }
        self.diagnostics.deinit(self.allocator);
    }

    pub fn reportError(
        self: *Diagnostics,
        message: []const u8,
        loc: SourceLoc,
        source: []const u8,
    ) !void {
        const owned_message = try self.allocator.dupe(u8, message);
        try self.diagnostics.append(self.allocator, .{
            .level = .@"error",
            .message = owned_message,
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
        const owned_message = try self.allocator.dupe(u8, message);
        try self.diagnostics.append(self.allocator, .{
            .level = .warning,
            .message = owned_message,
            .loc = loc,
            .source = source,
        });
    }

    pub fn hasErrors(self: *const Diagnostics) bool {
        for (self.diagnostics.items) |d| {
            if (d.level == .@"error") return true;
        }
        return false;
    }

    pub fn printAll(self: *const Diagnostics, writer: anytype) !void {
        for (self.diagnostics.items) |d| {
            try d.format("", .{}, writer);
        }
    }

    const StdDebugWriter = struct {
        pub fn print(
            _: *StdDebugWriter,
            comptime fmt: []const u8,
            args: anytype,
        ) !void {
            std.debug.print(fmt, args);
        }

        pub fn writeByte(
            _: *StdDebugWriter,
            b: u8,
        ) !void {
            std.debug.print("{c}", .{b});
        }
    };

    pub fn printAllStd(self: *const Diagnostics) !void {
        var w = StdDebugWriter{};
        try self.printAll(&w);
    }
};
