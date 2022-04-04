const std = @import("std");
const glfw = @import("glfw");
const render = @import("render/mod.zig");
const c = @import("c.zig");

const app_name = "Dear ImGui GLFW+Vulkan example";

pub fn main() !void {
    try glfw.init(.{});
    defer glfw.terminate();

    if (!glfw.vulkanSupported()) {
        @panic("GLFW: Vulkan Not Supported\n");
    }

    const width = 1280;
    const height = 720;
    const window = try glfw.Window.create(width, height, app_name, null, null, .{
        .client_api = .no_api,
    });
    defer window.destroy();

    // They're the same struct type, but defined in different includes of the
    // same header
    const handle = @ptrCast(*c.struct_GLFWwindow, window.handle);

    // Setup Dear ImGui context, return value is the context that's created
    _ = c.igCreateContext(null);
    defer c.igDestroyContext(null);

    const io = c.igGetIO();

    io.*.IniFilename = null;
    // io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;     // Enable
    // Keyboard Controls io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad; //
    // Enable Gamepad Controls

    // Setup Dear ImGui style
    c.igStyleColorsDark(null);
    // c.igStyleColorsLight(null);
    // c.igStyleColorsClassic(null);

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
