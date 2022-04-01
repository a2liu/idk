const std = @import("std");
const assert = std.debug.assert;
const ArrayList = std.ArrayList;
const alloc = @import("allocators.zig");
const gui = @import("gui/mod.zig");

pub fn hello(previous: []u8) anyerror!void {
    var _temp = alloc.Temp.init();
    defer _temp.deinit();

    const temp = _temp.allocator();

    var data = ArrayList(u8).init(temp);

    var i: u8 = 0;
    while (i < 100) {
        try data.append(i);

        i += 1;
    }

    i = 0;
    while (i < 100) {
        assert(data.items[i] == i);
        assert(previous[i] == i);

        i += 1;
    }
}

pub fn main() anyerror!void {
    var _temp = alloc.Temp.init();
    defer _temp.deinit();

    const temp = _temp.allocator();

    if (gui.raw.igSmallButton("Hello")) {
        std.debug.print("Hello world\n", .{});
    }

    var data = ArrayList(u8).init(temp);
    var i: u8 = 0;
    while (i < 100) {
        try data.append(i);

        i += 1;
    }

    i = 0;
    while (i < 100) {
        assert(data.items[i] == i);

        i += 1;
    }

    std.debug.print("entering hello\n", .{});

    try hello(data.items);

    i = 0;
    while (i < 100) {
        assert(data.items[i] == i);

        i += 1;
    }

    // var bump = alloc.Bump.init(1024 * 1024 * 4, alloc.Global);
    // var bump_alloc = bump.allocator();
    // var data2 = ArrayList(u8).init(bump_alloc);

    // i = 0;
    // while (i < 100) {
    //     try data2.append(i);

    //     i += 1;
    // }

    // bump.deinit();

    std.log.info("All your codebase are belong to us.", .{});
}
