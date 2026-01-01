const std = @import("std");

pub const CompileOptions = struct {
    source: []const u8,
    target: Target,
};

pub const Target = enum {
    ebpf,
};

pub const CompileResult = struct {
    elf: []u8,
};

pub fn compile(
    allocator: std.mem.Allocator,
    opts: CompileOptions,
) !CompileResult {
    const lexer = @import("lexer/lexer.zig");
    const parser = @import("parser/parser.zig");
    const irgen = @import("ir/ir.zig");
    const codegen = @import("codegen/ebpf.zig");
    const elf = @import("elf/writer.zig");

    const tokens = try lexer.lex(allocator, opts.source);
    const ast = try parser.parse(allocator, tokens);
    const ir = try irgen.lower(allocator, ast);
    const prog = try codegen.generate(allocator, ir);
    const image = try elf.write(allocator, prog);

    return .{ .elf = image };
}
