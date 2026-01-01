pub fn write(
    allocator: anytype,
    prog: anytype,
) ![]u8 {
    _ = prog;
    return try allocator.alloc(u8, 64);
}
