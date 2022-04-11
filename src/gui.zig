const std = @import("std");
const liu = @import("liu");
const c = @import("c.zig");

pub fn Text(comptime format: []const u8, args: anytype) void {
    var _temp = liu.Temp.init();
    const temp = _temp.allocator();
    defer _temp.deinit();

    const allocResult = std.fmt.allocPrint(temp, format, args);
    const s = allocResult catch @panic("failed to print");
    c.igTextUnformatted(s.ptr, s.ptr + s.len);
}
