const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const exe = b.addExecutable("aeonix", "src/main.zig");
    exe.setOutputPath("aeonix");
    exe.install();
}
