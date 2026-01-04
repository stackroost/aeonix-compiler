const std = @import("std");

// eBPF instruction encoding
const BPFInst = packed struct {
    code: u8, // opcode (4 bits) + src_reg (4 bits)
    dst_reg: u4, // destination register
    _: u4 = 0, // reserved
    off: i16, // offset
    imm: i32, // immediate value

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
const BPF_EXIT = 0x95; // BPF_JMP | BPF_EXIT

pub const ElfWriter = struct {
    allocator: std.mem.Allocator,
    buf: std.ArrayList(u8),
    license_data: ?[]const u8 = null,
    program_data: std.ArrayList(u8),
    current_section: ?[]const u8 = null,
    function_name: ?[]const u8 = null,

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

    pub fn beginProgram(self: *ElfWriter, section: []const u8, name: []const u8) !void {
        self.current_section = section;
        self.function_name = name;
        // Clear previous program data for new section
        self.program_data.clearRetainingCapacity();
    }

    pub fn emitLoadImm(self: *ElfWriter, reg: u8, val: i64) !void {
        if (val < std.math.minInt(i32) or val > std.math.maxInt(i32)) {
            return error.ImmediateOutOfRange;
        }

        const inst = BPFInst{
            .code = BPF_MOV64_IMM,
            .dst_reg = @truncate(reg),
            .off = 0,
            .imm = @intCast(val), // SAFE after check
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

        // Ensure we have a section name, default to ".text" if none provided
        const section_name = self.current_section orelse ".text";

        // -------------------
        // Build string table
        // -------------------
        var strtab = try std.ArrayList(u8).initCapacity(self.allocator, 512);
        defer strtab.deinit(self.allocator);

        // Start with null byte
        try strtab.append(self.allocator, 0);

        // Dynamic Section name (This fixes the "xdp" issue)
        const shstrtab_off_text = strtab.items.len;
        try strtab.appendSlice(self.allocator, section_name);
        try strtab.append(self.allocator, 0);

        const shstrtab_off_license = strtab.items.len;
        try strtab.appendSlice(self.allocator, ".license");
        try strtab.append(self.allocator, 0);

        const shstrtab_off_strtab = strtab.items.len;
        try strtab.appendSlice(self.allocator, ".strtab");
        try strtab.append(self.allocator, 0);

        const shstrtab_off_symtab = strtab.items.len;
        try strtab.appendSlice(self.allocator, ".symtab");
        try strtab.append(self.allocator, 0);

        // Symbol names
        const main_name_offset = strtab.items.len;
        try strtab.appendSlice(self.allocator, self.function_name orelse "main");
        try strtab.append(self.allocator, 0);

        // -------------------
        // Calculate offsets
        // -------------------
        const program_offset = ELF_HEADER_SIZE;
        const license_offset = program_offset + self.program_data.items.len;
        const strtab_offset = license_offset + (self.license_data.?.len + 1);
        const symtab_offset = strtab_offset + strtab.items.len;
        const shdr_offset = symtab_offset + 24 * 2;

        // -------------------
        // ELF HEADER (Standard BPF)
        // -------------------
        const ELF_MAGIC = [_]u8{ 0x7f, 'E', 'L', 'F' };
        try self.buf.appendSlice(self.allocator, &ELF_MAGIC);
        try self.buf.append(self.allocator, 2); // ELFCLASS64
        try self.buf.append(self.allocator, 1); // little endian
        try self.buf.append(self.allocator, 1); // version
        try self.buf.appendNTimes(self.allocator, 0, 9);

        const v = self.buf.writer(self.allocator);
        try v.writeInt(u16, 1, .little); // ET_REL
        try v.writeInt(u16, 247, .little); // EM_BPF
        try v.writeInt(u32, 1, .little); // EV_CURRENT

        try v.writeInt(u64, 0, .little); // entry
        try v.writeInt(u64, 0, .little); // phoff
        try v.writeInt(u64, shdr_offset, .little); // shoff

        try v.writeInt(u32, 0, .little); // flags
        try v.writeInt(u16, ELF_HEADER_SIZE, .little);
        try v.writeInt(u16, 0, .little);
        try v.writeInt(u16, 0, .little);
        try v.writeInt(u16, SECTION_HEADER_SIZE, .little);
        try v.writeInt(u16, 5, .little); // shnum
        try v.writeInt(u16, 3, .little); // shstrndx

        while (self.buf.items.len < program_offset) try self.buf.append(self.allocator, 0);

        // Data Sections
        try self.buf.appendSlice(self.allocator, self.program_data.items);

        const license_str = self.license_data orelse "GPL";
        try self.buf.appendSlice(self.allocator, license_str);
        try self.buf.append(self.allocator, 0);
        try self.buf.appendSlice(self.allocator, strtab.items);

        // Symbol Table
        var symtab_buf = try std.ArrayList(u8).initCapacity(self.allocator, 64);
        defer symtab_buf.deinit(self.allocator);
        try symtab_buf.appendSlice(self.allocator, &[_]u8{0} ** 24); // Null sym

        var main_sym: [24]u8 = undefined;
        // FIX: Replaced @as with @intCast to resolve the usize -> u32 error
        std.mem.writeInt(u32, main_sym[0..4], @intCast(main_name_offset), .little);
        main_sym[4] = (1 << 4) | (2 & 0xF); // STB_GLOBAL | STT_FUNC
        main_sym[5] = 0;
        std.mem.writeInt(u16, main_sym[6..8], 1, .little); // section 1
        std.mem.writeInt(u64, main_sym[8..16], 0, .little);
        std.mem.writeInt(u64, main_sym[16..24], self.program_data.items.len, .little);

        try symtab_buf.appendSlice(self.allocator, &main_sym);
        try self.buf.appendSlice(self.allocator, symtab_buf.items);

        // -------------------
        // SECTION HEADER TABLE
        // -------------------
        const writer = self.buf.writer(self.allocator);

        // 0: Null
        try writer.writeBytesNTimes(&[_]u8{0}, 64);

        // 1: Program Section (Now using dynamic name index)
        try writer.writeInt(u32, @intCast(shstrtab_off_text), .little);
        try writer.writeInt(u32, 1, .little); // SHT_PROGBITS
        try writer.writeInt(u64, 6, .little); // SHF_ALLOC | SHF_EXECINSTR
        try writer.writeInt(u64, 0, .little);
        try writer.writeInt(u64, program_offset, .little);
        try writer.writeInt(u64, self.program_data.items.len, .little);
        try writer.writeInt(u32, 0, .little);
        try writer.writeInt(u32, 0, .little);
        try writer.writeInt(u64, 8, .little); // Alignment
        try writer.writeInt(u64, 0, .little);

        // 2: .license (FIX: Replaced @as with @intCast)
        try writer.writeInt(u32, @intCast(shstrtab_off_license), .little);
        try writer.writeInt(u32, 1, .little); // SHT_PROGBITS
        try writer.writeInt(u64, 2, .little); // SHF_ALLOC (Libbpf needs this to 'see' the section)
        try writer.writeInt(u64, 0, .little);
        try writer.writeInt(u64, license_offset, .little);
        try writer.writeInt(u64, license_str.len + 1, .little); // Include the null terminator
        try writer.writeInt(u32, 0, .little);
        try writer.writeInt(u32, 0, .little);
        try writer.writeInt(u64, 1, .little); // Alignment
        try writer.writeInt(u64, 0, .little);

        // 3: .strtab (FIX: Replaced @as with @intCast)
        try writer.writeInt(u32, @intCast(shstrtab_off_strtab), .little);
        try writer.writeInt(u32, 3, .little);
        try writer.writeInt(u64, 0, .little);
        try writer.writeInt(u64, 0, .little);
        try writer.writeInt(u64, strtab_offset, .little);
        try writer.writeInt(u64, strtab.items.len, .little);
        try writer.writeInt(u32, 0, .little);
        try writer.writeInt(u32, 0, .little);
        try writer.writeInt(u64, 1, .little);
        try writer.writeInt(u64, 0, .little);

        // 4: .symtab (FIX: Replaced @as with @intCast)
        try writer.writeInt(u32, @intCast(shstrtab_off_symtab), .little);
        try writer.writeInt(u32, 2, .little);
        try writer.writeInt(u64, 0, .little);
        try writer.writeInt(u64, 0, .little);
        try writer.writeInt(u64, symtab_offset, .little);
        try writer.writeInt(u64, symtab_buf.items.len, .little);
        try writer.writeInt(u32, 3, .little);
        try writer.writeInt(u32, 1, .little);
        try writer.writeInt(u64, 8, .little);
        try writer.writeInt(u64, 24, .little);

        return self.buf.toOwnedSlice(self.allocator);
    }

    pub fn deinit(self: *ElfWriter) void {
        self.buf.deinit(self.allocator);
        self.program_data.deinit(self.allocator);
    }
};
