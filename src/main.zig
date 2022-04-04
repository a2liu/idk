const std = @import("std");
const glfw = @import("glfw");
const render = @import("render/mod.zig");
const c = @import("c.zig");

pub fn main() !void {
    try glfw.init(.{});

    const result = c.cpp_main();
    if (result != 0) {
        const pressed = c.igSmallButton("Hello");
        _ = pressed;

        @panic("rippo bro");
    }
}
