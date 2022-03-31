const std = @import("std");
const alloc = @import("allocators.zig");

pub fn main() anyerror!void {
    var allocator = alloc.stack();
    std.log.info("All your codebase are belong to us.", .{});
}
