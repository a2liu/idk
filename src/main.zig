const std = @import("std");
const alloc = @import("allocators.zig");
const glfw = @import("glfw");
const util = @import("util.zig");
const gui = @import("gui.zig");
const render = @import("render.zig");
const c = @import("c.zig");
const app = @import("app.zig");

// This file mostly contains plumbing to get this app to work.
const app_name = "Dear ImGui GLFW+Vulkan example";
const cstr_z = [*:0]const u8;
const cstr = [*c]const u8;

pub fn main() !void {
    try glfw.init(.{});
    defer glfw.terminate();

    if (!glfw.vulkanSupported()) {
        @panic("GLFW: Vulkan Not Supported\n");
    }

    const i_width = 1280;
    const i_height = 720;
    const window = try glfw.Window.create(i_width, i_height, app_name, null, null, .{
        .client_api = .no_api,
    });
    defer window.destroy();

    // Setup Dear ImGui context, return value is the context that's created
    _ = c.igCreateContext(null);
    defer c.igDestroyContext(null);

    {
        const io = c.igGetIO();
        io.*.IniFilename = null;
        c.igStyleColorsDark(null); // Setup Dear ImGui style
    }

    try render.setupVulkan(window, i_width, i_height);
    defer render.teardownVulkan();

    var rebuild_chain = false;

    var state = app.AppState{};
    var timer = util.SimTimer.init();

    while (!window.shouldClose()) {
        state.frameDelta = timer.frameTimeMs();
        state.computeDelta = timer.prevFrameComputeMs();

        // Poll and handle events (inputs, window resize, etc.)
        // You can read the io.WantCaptureMouse, io.WantCaptureKeyboard flags to
        // tell if dear imgui wants to use your inputs.
        // - When io.WantCaptureMouse is true, do not dispatch mouse input data to
        // your main application, or clear/overwrite your copy of the mouse data.
        // - When io.WantCaptureKeyboard is true, do not dispatch keyboard input
        // data to your main application, or clear/overwrite your copy of the
        // keyboard data. Generally you may always pass all inputs to dear imgui,
        // and hide them from your application based on those two flags.
        try glfw.pollEvents();

        alloc.clearFrameAllocator();

        if (rebuild_chain) {
            // var width: c_int = undefined;
            // var height: c_int = undefined;

            const size = try window.getFramebufferSize();
            // c.glfwGetFramebufferSize(handle, &width, &height);

            if (size.width > 0 and size.height > 0) {
                c.ImGui_ImplVulkan_SetMinImageCount(2);
                c.ImGui_ImplVulkanH_CreateOrResizeWindow(
                    render.g_Instance,
                    render.g_PhysicalDevice,
                    render.g_Device,
                    &render.g_MainWindowData,
                    render.g_QueueFamily,
                    null,
                    @bitCast(c_int, size.width),
                    @bitCast(c_int, size.height),
                    2,
                );

                render.g_MainWindowData.FrameIndex = 0;
            }

            rebuild_chain = false;
        }

        c.ImGui_ImplVulkan_NewFrame();
        c.ImGui_ImplGlfw_NewFrame();
        c.igNewFrame();

        try app.run(&state);

        c.igRender();

        const draw_data = c.igGetDrawData();
        const display_size = draw_data.*.DisplaySize;
        const is_minimized = display_size.x <= 0.0 or display_size.y <= 0.0;

        if (!is_minimized) {
            const clear_color = state.clear_color;
            const wd = &render.g_MainWindowData;
            wd.ClearValue.color.float32[0] = clear_color.x * clear_color.w;
            wd.ClearValue.color.float32[1] = clear_color.y * clear_color.w;
            wd.ClearValue.color.float32[2] = clear_color.z * clear_color.w;
            wd.ClearValue.color.float32[3] = clear_color.w;

            rebuild_chain = render.renderFrame(wd, draw_data);
        }
    }
}
