const std = @import("std");

// Frontend
const lexer = @import("frontend/lexer.zig");
const parser = @import("frontend/parser.zig");
const sema = @import("frontend/sema.zig");

// Middle
const ir_mod = @import("middle/ir.zig");
const lower = @import("middle/lower.zig");

// Backend
const codegen = @import("backend/ebpf/codegen.zig");
const elf_writer = @import("backend/elf/writer.zig");

pub const Mode = enum { build, check, emit_ir, run };

pub fn compileFile(
    alloc: std.mem.Allocator,
    mode: Mode,
    in_path: []const u8,
    out_path_opt: ?[]const u8,
) !void {
    const src = try std.fs.cwd().readFileAlloc(alloc, in_path, 10 * 1024 * 1024);
    defer alloc.free(src);

    // 0.15.x stdout writer (buffered + interface + flush)
    var stdout_buf: [4096]u8 = undefined;
    var stdout_wr = std.fs.File.stdout().writer(&stdout_buf);
    const out: *std.Io.Writer = &stdout_wr.interface;
    defer out.flush() catch {};

    // 1) Lexer
    var tokens = try lexer.tokenize(alloc, src);
    defer tokens.deinit(alloc);

    // 2) Parser -> AST
    var ast = try parser.parse(alloc, src, tokens.items);
    defer ast.deinit(alloc);

    // 3) Sema (Stage-0 checks)
    try sema.check(&ast);

    if (mode == .check) {
        try out.print("ok: {s}\n", .{in_path});
        return;
    }

    // 4) AST -> IR
    var ir = try ir_mod.fromAst(alloc, &ast);
    defer ir.deinit(alloc);

    if (mode == .emit_ir) {
        try ir.dump(out);
        return;
    }

    // 5) IR -> eBPF bytecode
    var obj = try codegen.generate(alloc, &ir);
    defer obj.deinit(alloc);

    // 6) ELF writer
    const out_path = out_path_opt orelse defaultOutPath(alloc, in_path) catch "out.o";
    defer if (out_path_opt == null) alloc.free(out_path);

    try elf_writer.writeObject(out_path, &obj);

    try out.print("built: {s}\n", .{out_path});

    if (mode == .run) {
        try out.print("note: `run` will load+attach in a later stage.\n", .{});
    }
}

fn defaultOutPath(alloc: std.mem.Allocator, in_path: []const u8) ![]const u8 {
    if (std.mem.endsWith(u8, in_path, ".snx")) {
        return std.fmt.allocPrint(alloc, "{s}.o", .{in_path[0 .. in_path.len - 4]});
    }
    return std.fmt.allocPrint(alloc, "{s}.o", .{in_path});
}
