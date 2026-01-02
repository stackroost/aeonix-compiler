const std = @import("std");

pub const ElfWriter = struct {
    allocator: std.mem.Allocator,
    buf: std.ArrayList(u8),

    pub fn init(allocator: std.mem.Allocator) !ElfWriter {
        return .{
            .allocator = allocator,
            .buf = try std.ArrayList(u8).initCapacity(allocator, 0),
        };
    }

    pub fn emitLicense(self: *ElfWriter, license: ?[]const u8) !void {
        _ = self;
        _ = license; // we embed later (minimal version)
    }

    pub fn beginProgram(self: *ElfWriter, section: []const u8) !void {
        _ = self;
        _ = section;
    }

    pub fn emitLoadImm(self: *ElfWriter, reg: u8, val: i64) !void {
        _ = self;
        _ = reg;
        _ = val;
    }

    pub fn emitExit(self: *ElfWriter) !void {
        _ = self;
    }

    pub fn finish(self: *ElfWriter) ![]u8 {
        // ===== ELF HEADER =====
        const ELF_MAGIC = [_]u8{ 0x7f, 'E', 'L', 'F' };

        try self.buf.appendSlice(self.allocator, &ELF_MAGIC); // e_ident[0..4]
        try self.buf.append(self.allocator, 2); // ELFCLASS64
        try self.buf.append(self.allocator, 1); // little endian
        try self.buf.append(self.allocator, 1); // ELF version
        try self.buf.appendNTimes(self.allocator, 0, 9); // padding

        try self.buf.writer(self.allocator).writeInt(u16, 1, .little); // ET_REL
        try self.buf.writer(self.allocator).writeInt(u16, 247, .little); // EM_BPF
        try self.buf.writer(self.allocator).writeInt(u32, 1, .little); // EV_CURRENT

        // entry, phoff, shoff
        try self.buf.writer(self.allocator).writeInt(u64, 0, .little);
        try self.buf.writer(self.allocator).writeInt(u64, 0, .little);
        try self.buf.writer(self.allocator).writeInt(u64, 0, .little);

        // flags
        try self.buf.writer(self.allocator).writeInt(u32, 0, .little);

        // header sizes
        try self.buf.writer(self.allocator).writeInt(u16, 64, .little); // ehsize
        try self.buf.writer(self.allocator).writeInt(u16, 0, .little); // phentsize
        try self.buf.writer(self.allocator).writeInt(u16, 0, .little); // phnum
        try self.buf.writer(self.allocator).writeInt(u16, 0, .little); // shentsize
        try self.buf.writer(self.allocator).writeInt(u16, 0, .little); // shnum
        try self.buf.writer(self.allocator).writeInt(u16, 0, .little); // shstrndx

        return self.buf.toOwnedSlice(self.allocator);
    }

    pub fn deinit(self: *ElfWriter) void {
        self.buf.deinit(self.allocator);
    }
};
