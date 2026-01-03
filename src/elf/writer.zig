const std = @import("std");

// eBPF instruction encoding
const BPFInst = packed struct {
    code: u8,      // opcode (4 bits) + src_reg (4 bits)
    dst_reg: u4,   // destination register
    _: u4 = 0,     // reserved
    off: i16,      // offset
    imm: i32,      // immediate value

    pub fn encode(self: BPFInst) [8]u8 {
        var bytes: [8]u8 = undefined;
        bytes[0] = self.code;
        bytes[1] = (@as(u8, self.dst_reg) << 4) | (@as(u8, self._) & 0x0F);
        std.mem.writeInt(i16, bytes[2..4], self.off, .little);
        std.mem.writeInt(i32, bytes[4..8], self.imm, .little);
        return bytes;
    }
};

// eBPF opcodes
const BPF_MOV64_IMM = 0xb7; // BPF_ALU64 | BPF_MOV | BPF_K
const BPF_EXIT = 0x95;       // BPF_JMP | BPF_EXIT

pub const ElfWriter = struct {
    allocator: std.mem.Allocator,
    buf: std.ArrayList(u8),
    license_data: ?[]const u8 = null,
    program_data: std.ArrayList(u8),
    current_section: ?[]const u8 = null,

    pub fn init(allocator: std.mem.Allocator) !ElfWriter {
        return .{
            .allocator = allocator,
            .buf = try std.ArrayList(u8).initCapacity(allocator, 1024),
            .program_data = try std.ArrayList(u8).initCapacity(allocator, 256),
        };
    }

    pub fn emitLicense(self: *ElfWriter, license: ?[]const u8) !void {
        self.license_data = license orelse "GPL";
    }

    pub fn beginProgram(self: *ElfWriter, section: []const u8) !void {
        self.current_section = section;
        // Clear previous program data for new section
        self.program_data.clearRetainingCapacity();
    }

    pub fn emitLoadImm(self: *ElfWriter, reg: u8, val: i64) !void {
        // BPF_MOV64_IMM: Move immediate value to register
        const inst = BPFInst{
            .code = BPF_MOV64_IMM,
            .dst_reg = @truncate(reg),
            .off = 0,
            .imm = @truncate(@as(i32, val)),
        };
        const bytes = inst.encode();
        try self.program_data.appendSlice(self.allocator, &bytes);
    }

    pub fn emitExit(self: *ElfWriter) !void {
        // BPF_EXIT: Exit program
        const inst = BPFInst{
            .code = BPF_EXIT,
            .dst_reg = 0,
            .off = 0,
            .imm = 0,
        };
        const bytes = inst.encode();
        try self.program_data.appendSlice(self.allocator, &bytes);
    }

    pub fn finish(self: *ElfWriter) ![]u8 {
        const ELF_HEADER_SIZE = 64;
        const SECTION_HEADER_SIZE = 64;
        
        // Build string table
        var strtab = std.ArrayList(u8).initCapacity(self.allocator, 256) catch return error.OutOfMemory;
        defer strtab.deinit(self.allocator);
        
        // String table starts with null byte
        try strtab.append(self.allocator, 0);
        
        // Add section names
        const shstrtab_off_text = strtab.items.len;
        try strtab.appendSlice(self.allocator, ".text");
        try strtab.append(self.allocator, 0);
        
        const shstrtab_off_license = strtab.items.len;
        try strtab.appendSlice(self.allocator, ".license");
        try strtab.append(self.allocator, 0);
        
        const shstrtab_off_strtab = strtab.items.len;
        try strtab.appendSlice(self.allocator, ".strtab");
        try strtab.append(self.allocator, 0);
        
        // Calculate offsets
        const program_offset = ELF_HEADER_SIZE;
        const license_offset = program_offset + self.program_data.items.len;
        const strtab_offset = license_offset + (self.license_data.?.len + 1);
        const shdr_offset = strtab_offset + strtab.items.len;
        
        // ===== ELF HEADER =====
        const ELF_MAGIC = [_]u8{ 0x7f, 'E', 'L', 'F' };
        
        try self.buf.appendSlice(self.allocator, &ELF_MAGIC);
        try self.buf.append(self.allocator, 2); // ELFCLASS64
        try self.buf.append(self.allocator, 1); // little endian
        try self.buf.append(self.allocator, 1); // ELF version
        try self.buf.appendNTimes(self.allocator, 0, 9); // padding
        
        try self.buf.writer(self.allocator).writeInt(u16, 1, .little); // ET_REL
        try self.buf.writer(self.allocator).writeInt(u16, 247, .little); // EM_BPF
        try self.buf.writer(self.allocator).writeInt(u32, 1, .little); // EV_CURRENT
        
        // entry, phoff
        try self.buf.writer(self.allocator).writeInt(u64, 0, .little);
        try self.buf.writer(self.allocator).writeInt(u64, 0, .little);
        // shoff - points to section header table
        try self.buf.writer(self.allocator).writeInt(u64, shdr_offset, .little);
        
        // flags
        try self.buf.writer(self.allocator).writeInt(u32, 0, .little);
        
        // header sizes
        try self.buf.writer(self.allocator).writeInt(u16, ELF_HEADER_SIZE, .little); // ehsize
        try self.buf.writer(self.allocator).writeInt(u16, 0, .little); // phentsize
        try self.buf.writer(self.allocator).writeInt(u16, 0, .little); // phnum
        try self.buf.writer(self.allocator).writeInt(u16, SECTION_HEADER_SIZE, .little); // shentsize
        try self.buf.writer(self.allocator).writeInt(u16, 4, .little); // shnum (null + text + license + strtab)
        try self.buf.writer(self.allocator).writeInt(u16, 3, .little); // shstrndx (index of .strtab section)
        
        // Pad to program_offset if needed
        while (self.buf.items.len < program_offset) {
            try self.buf.append(self.allocator, 0);
        }
        
        // ===== PROGRAM SECTION (.text) =====
        try self.buf.appendSlice(self.allocator, self.program_data.items);
        
        // ===== LICENSE SECTION =====
        const license_str = self.license_data orelse "GPL";
        try self.buf.appendSlice(self.allocator, license_str);
        try self.buf.append(self.allocator, 0); // null terminator
        
        // ===== STRING TABLE (.strtab) =====
        try self.buf.appendSlice(self.allocator, strtab.items);
        
        // ===== SECTION HEADER TABLE =====
        // Null section header (index 0)
        try self.buf.writer(self.allocator).writeInt(u32, 0, .little); // sh_name
        try self.buf.writer(self.allocator).writeInt(u32, 0, .little); // sh_type
        try self.buf.writer(self.allocator).writeInt(u64, 0, .little); // sh_flags
        try self.buf.writer(self.allocator).writeInt(u64, 0, .little); // sh_addr
        try self.buf.writer(self.allocator).writeInt(u64, 0, .little); // sh_offset
        try self.buf.writer(self.allocator).writeInt(u64, 0, .little); // sh_size
        try self.buf.writer(self.allocator).writeInt(u32, 0, .little); // sh_link
        try self.buf.writer(self.allocator).writeInt(u32, 0, .little); // sh_info
        try self.buf.writer(self.allocator).writeInt(u64, 0, .little); // sh_addralign
        try self.buf.writer(self.allocator).writeInt(u64, 0, .little); // sh_entsize
        
        // .text section header (index 1)
        try self.buf.writer(self.allocator).writeInt(u32, @as(u32, @intCast(shstrtab_off_text)), .little); // sh_name
        try self.buf.writer(self.allocator).writeInt(u32, 1, .little); // SHT_PROGBITS
        try self.buf.writer(self.allocator).writeInt(u64, 6, .little); // SHF_ALLOC | SHF_EXECINSTR
        try self.buf.writer(self.allocator).writeInt(u64, 0, .little); // sh_addr
        try self.buf.writer(self.allocator).writeInt(u64, program_offset, .little); // sh_offset
        try self.buf.writer(self.allocator).writeInt(u64, self.program_data.items.len, .little); // sh_size
        try self.buf.writer(self.allocator).writeInt(u32, 0, .little); // sh_link
        try self.buf.writer(self.allocator).writeInt(u32, 0, .little); // sh_info
        try self.buf.writer(self.allocator).writeInt(u64, 8, .little); // sh_addralign
        try self.buf.writer(self.allocator).writeInt(u64, 0, .little); // sh_entsize
        
        // .license section header (index 2)
        try self.buf.writer(self.allocator).writeInt(u32, @as(u32, @intCast(shstrtab_off_license)), .little); // sh_name
        try self.buf.writer(self.allocator).writeInt(u32, 1, .little); // SHT_PROGBITS
        try self.buf.writer(self.allocator).writeInt(u64, 3, .little); // SHF_ALLOC | SHF_WRITE
        try self.buf.writer(self.allocator).writeInt(u64, 0, .little); // sh_addr
        try self.buf.writer(self.allocator).writeInt(u64, license_offset, .little); // sh_offset
        try self.buf.writer(self.allocator).writeInt(u64, license_str.len + 1, .little); // sh_size
        try self.buf.writer(self.allocator).writeInt(u32, 0, .little); // sh_link
        try self.buf.writer(self.allocator).writeInt(u32, 0, .little); // sh_info
        try self.buf.writer(self.allocator).writeInt(u64, 1, .little); // sh_addralign
        try self.buf.writer(self.allocator).writeInt(u64, 0, .little); // sh_entsize
        
        // .strtab section header (index 3)
        try self.buf.writer(self.allocator).writeInt(u32, @as(u32, @intCast(shstrtab_off_strtab)), .little); // sh_name
        try self.buf.writer(self.allocator).writeInt(u32, 3, .little); // SHT_STRTAB
        try self.buf.writer(self.allocator).writeInt(u64, 0, .little); // sh_flags
        try self.buf.writer(self.allocator).writeInt(u64, 0, .little); // sh_addr
        try self.buf.writer(self.allocator).writeInt(u64, strtab_offset, .little); // sh_offset
        try self.buf.writer(self.allocator).writeInt(u64, strtab.items.len, .little); // sh_size
        try self.buf.writer(self.allocator).writeInt(u32, 0, .little); // sh_link
        try self.buf.writer(self.allocator).writeInt(u32, 0, .little); // sh_info
        try self.buf.writer(self.allocator).writeInt(u64, 1, .little); // sh_addralign
        try self.buf.writer(self.allocator).writeInt(u64, 0, .little); // sh_entsize
        
        return self.buf.toOwnedSlice(self.allocator);
    }

    pub fn deinit(self: *ElfWriter) void {
        self.buf.deinit(self.allocator);
        self.program_data.deinit(self.allocator);
    }
};
