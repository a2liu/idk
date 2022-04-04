const std = @import("std");
const glfw = @import("glfw");
const render = @import("render/mod.zig");
const c = @import("c.zig");

pub extern "C" fn cpp_main() c_int;

pub fn main() !void {
    try glfw.init(.{});

    const result = cpp_main();
    if (result != 0) {
        const pressed = c.igSmallButton("Hello");
        _ = pressed;

        @panic("rippo bro");
    }
}
