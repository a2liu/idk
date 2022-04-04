const std = @import("std");
const glfw = @import("glfw");
const render = @import("render/mod.zig");
const c = @import("c.zig");

const app_name = "Dear ImGui GLFW+Vulkan example";

pub fn main() !void {
    try glfw.init(.{});

    const width = 1280;
    const height = 720;
    const window = try glfw.Window.create(width, height, app_name, null, null, .{
        .client_api = .no_api,
    });

    // They're the same struct type, but defined in different includes of the
    // same header
    const handle = @ptrCast(*c.struct_GLFWwindow, window.handle);

    c.cpp_init(handle);

    while (!window.shouldClose()) {
        c.cpp_loop(handle);

        std.time.sleep(1000 * 1000);
    }

    const result = c.cpp_teardown(handle);

    if (result != 0) {
        const pressed = c.igSmallButton("Hello");
        _ = pressed;

        @panic("rippo bro");
    }
}
