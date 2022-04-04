const std = @import("std");
const alloc = @import("./allocators.zig");
const glfw = @import("glfw");
const gui = @import("gui/mod.zig");
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

    {
        const io = c.igGetIO();
        io.*.IniFilename = null;
        c.igStyleColorsDark(null); // Setup Dear ImGui style
    }

    c.cpp_init(handle);

    var show_demo_window = true;
    var show_another_window = false;
    var float_value: f32 = 0.0;
    var counter_value: i32 = 0;
    var clear_color = c.ImVec4{ .x = 0.45, .y = 0.55, .z = 0.60, .w = 1.00 };

    while (!window.shouldClose()) {
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

        c.cpp_resize_swapchain(handle);
        c.cpp_new_frame();
        c.igNewFrame();
        alloc.clearFrameAllocator();

        // 1. Show the big demo window (Most of the sample code is in
        // ImGui::ShowDemoWindow()! You can browse its code to learn more about Dear
        // ImGui!).
        if (show_demo_window) {
            c.igShowDemoWindow(&show_demo_window);
        }

        // 2. Show a simple window that we create ourselves. We use a Begin/End pair
        // to created a named window.
        {
            // Create a window called "Hello, world!" and append into it.
            _ = c.igBegin("Hello, world!", null, 0);

            // Display some text (you can use a format strings too)
            gui.Text("This is some useful text.", .{});

            // Edit bools storing our window open/close state
            _ = c.igCheckbox("Demo Window", &show_demo_window);
            _ = c.igCheckbox("Another Window", &show_another_window);

            // Edit 1 float using a slider from 0.0f to 1.0f
            // return value is whether value changed
            _ = c.igSliderFloat("float", &float_value, 0.0, 1.0, "%.3f", 0);

            // Edit 3 floats representing a color
            _ = c.igColorEdit3("clear color", @ptrCast(*f32, &clear_color), 0);

            // Buttons return true when clicked (most widgets return true when
            // edited/activated)
            if (c.igButton("Button", .{ .x = 0, .y = 0 })) {
                counter_value += 1;
            }

            c.igSameLine(0.0, -1.0);
            gui.Text("counter = {}", .{counter_value});

            const io: [*c]volatile c.ImGuiIO = c.igGetIO();
            const fps = io.*.Framerate;
            const frame_time = 1000.0 / fps;
            gui.Text(
                "Application average {d:.3} ms/frame ({d:.1} FPS)",
                .{ frame_time, fps },
            );

            c.igEnd();
        }

        // 3. Show another simple window.
        if (show_another_window) {
            // Pass a pointer to our bool variable (the
            // window will have a closing button that will
            // clear the bool when clicked)
            _ = c.igBegin("Another Window", &show_another_window, 0);

            gui.Text("Hello from another window!", .{});
            if (c.igButton("Close Me", .{ .x = 0, .y = 0 })) {
                show_another_window = false;
            }

            c.igEnd();
        }

        c.igRender();
        const draw_data = c.igGetDrawData();
        c.cpp_render(handle, draw_data, clear_color);

        std.time.sleep(1000 * 1000);
    }

    const result = c.cpp_teardown(handle);

    if (result != 0) {
        const pressed = c.igSmallButton("Hello");
        _ = pressed;

        @panic("rippo bro");
    }
}
