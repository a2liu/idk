const std = @import("std");
const alloc = @import("./allocators.zig");
const glfw = @import("glfw");
const gui = @import("gui.zig");
const render = @import("render/mod.zig");
const c = @import("c.zig");

const app_name = "Dear ImGui GLFW+Vulkan example";

const todoApp = @import("todo.zig").todoApp;

const OpenApps = struct {
    demo: bool = true,
    todo: bool = true,
};

var float_value: f32 = 0.0;
var counter_value: i32 = 0;
var clear_color = c.ImVec4{ .x = 0.45, .y = 0.55, .z = 0.60, .w = 1.00 };

fn navigator(meta: *OpenApps) void {
    const pivot = .{ .x = 0, .y = 0 };
    c.igSetNextWindowPos(.{ .x = 0, .y = 0 }, c.ImGuiCond_FirstUseEver, pivot);

    // Create a window called "Hello, world!" and append into it.
    _ = c.igBegin("Hello, world!", null, 0);
    defer c.igEnd();

    // Display some text (you can use a format strings too)
    gui.Text("This is some useful text.", .{});

    // Edit bools storing our window open/close state
    _ = c.igCheckbox("Demo Window", &meta.demo);
    _ = c.igCheckbox("Todo App", &meta.todo);

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
}

pub fn setupVulkan() !void {
    var _temp = alloc.Temp.init();
    const temp = _temp.allocator();
    defer _temp.deinit();

    var count: u32 = 0;
    const glfw_ext = c.glfwGetRequiredInstanceExtensions(&count);

    const ext = try temp.alloc([*c]const u8, count + 1);
    std.mem.copy([*c]const u8, ext, glfw_ext[0..count]);

    ext[count] = "VK_EXT_debug_report";

    c.cpp_SetupVulkan(ext.ptr, count + 1);
}

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

    try setupVulkan();

    // Setup Dear ImGui context, return value is the context that's created
    _ = c.igCreateContext(null);
    defer c.igDestroyContext(null);

    {
        const io = c.igGetIO();
        io.*.IniFilename = null;
        c.igStyleColorsDark(null); // Setup Dear ImGui style
    }

    c.cpp_init(handle);

    var open_apps = OpenApps{};

    var rebuild_chain = false;

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

        alloc.clearFrameAllocator();

        if (rebuild_chain) {
            c.cpp_resize_swapchain(handle);
        }

        c.ImGui_ImplVulkan_NewFrame();
        c.ImGui_ImplGlfw_NewFrame();
        c.igNewFrame();

        navigator(&open_apps);

        if (open_apps.demo) {
            c.igShowDemoWindow(&open_apps.demo);
        }

        if (open_apps.todo) {
            const pivot = .{ .x = 0, .y = 0 };
            const point = .{ .x = 200, .y = 200 };
            c.igSetNextWindowPos(point, c.ImGuiCond_FirstUseEver, pivot);
            try todoApp(&open_apps.todo);
        }

        c.igRender();

        const draw_data = c.igGetDrawData();
        const display_size = draw_data.*.DisplaySize;
        const is_minimized = display_size.x <= 0.0 or display_size.y <= 0.0;
        if (!is_minimized) {
            rebuild_chain = c.cpp_render(handle, draw_data, clear_color);
        }

        std.time.sleep(1000 * 1000);
    }

    const result = c.cpp_teardown(handle);

    if (result != 0) {
        const pressed = c.igSmallButton("Hello");
        _ = pressed;

        @panic("rippo bro");
    }
}
