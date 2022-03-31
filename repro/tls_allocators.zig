const std = @import("std");
const print = std.debug.print;
const mem = std.mem;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;

pub const Pages = std.heap.page_allocator;

const Storage = struct {
    data: ArrayList(u8),
};

const TempStorageInitialSize = 1024 * 1024 * 4;
threadlocal var temporary_storage: Storage = .{
    .data = ArrayList(u8).init(Pages),
};

pub fn main() anyerror!void {
    // workaround I'm using right now
    // temporary_storage.ranges.allocator = Pages;
    // defer temporary_storage.ranges.deinit();

    try temporary_storage.data.append(1);
    print("done!\n", .{});
}
