const std = @import("std");
const alloc = @import("./allocators.zig");
const glfw = @import("glfw");
const gui = @import("gui.zig");
const render = @import("render/mod.zig");
const c = @import("c.zig");
const app = @import("app.zig");

// This file mostly contains plumbing to get this app to work.
const app_name = "Dear ImGui GLFW+Vulkan example";

fn checkVkResult(err: c.VkResult) void {
    if (err == 0) return;

    std.debug.print("[vulkan] Error: VkResult = {}\n", .{err});
    if (err < 0)
        @panic("[vulkan] aborted");
}

fn setupVulkan() !void {
    var _temp = alloc.Temp.init();
    const temp = _temp.allocator();
    defer _temp.deinit();

    var err: c.VkResult = undefined;

    const cstr = [*c]const u8;

    {
        var count: u32 = 0;
        const glfw_ext = c.glfwGetRequiredInstanceExtensions(&count);

        const ext = try temp.alloc(cstr, count + 1);
        std.mem.copy(cstr, ext, glfw_ext[0..count]);

        ext[count] = "VK_EXT_debug_report";

        const layers: []const cstr = &[_]cstr{"VK_LAYER_KHRONOS_validation"};
        const create_info = c.VkInstanceCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
            .enabledExtensionCount = count + 1,
            .ppEnabledExtensionNames = ext.ptr,
            .enabledLayerCount = 1,
            .ppEnabledLayerNames = layers.ptr,
            .pNext = null,
            .flags = 0,
            .pApplicationInfo = 0,
        };

        err = c.vkCreateInstance(&create_info, null, &c.g_Instance);
        checkVkResult(err);

        const callback = cb: {
            const raw_callback = c.vkGetInstanceProcAddr(c.g_Instance, "vkCreateDebugReportCallbackEXT");
            if (@ptrCast(c.PFN_vkCreateDebugReportCallbackEXT, raw_callback)) |cb| {
                break :cb cb;
            }

            @panic("rip");
        };

        var debug_report_ci = c.VkDebugReportCallbackCreateInfoEXT{
            .sType = c.VK_STRUCTURE_TYPE_DEBUG_REPORT_CALLBACK_CREATE_INFO_EXT,
            .flags = c.VK_DEBUG_REPORT_ERROR_BIT_EXT |
                c.VK_DEBUG_REPORT_WARNING_BIT_EXT |
                c.VK_DEBUG_REPORT_PERFORMANCE_WARNING_BIT_EXT,
            .pfnCallback = c.debug_report,
            .pNext = null,
            .pUserData = null,
        };

        err = callback(c.g_Instance, &debug_report_ci, null, &c.g_DebugReport);
        checkVkResult(err);
    }

    // Select GPU
    c.g_PhysicalDevice = select_gpu: {
        var count: u32 = 0;
        err = c.vkEnumeratePhysicalDevices(c.g_Instance, &count, null);
        checkVkResult(err);
        std.debug.assert(count > 0);

        const gpus = try temp.alloc(c.VkPhysicalDevice, count);
        err = c.vkEnumeratePhysicalDevices(c.g_Instance, &count, gpus.ptr);
        checkVkResult(err);

        // If a number >1 of GPUs got reported, find discrete GPU if present, or use
        // first one available. This covers most common cases
        // (multi-gpu/integrated+dedicated graphics). Handling more complicated
        // setups (multiple dedicated GPUs) is out of scope of this sample.
        for (gpus) |gpu| {
            var properties: c.VkPhysicalDeviceProperties = undefined;
            c.vkGetPhysicalDeviceProperties(gpu, &properties);
            if (properties.deviceType == c.VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU) {
                break :select_gpu gpu;
            }
        }

        break :select_gpu gpus[0];
    };

    // Select graphics queue family
    c.g_QueueFamily = queue_family: {
        const getProperties = c.vkGetPhysicalDeviceQueueFamilyProperties;

        var count: u32 = 0;
        getProperties(c.g_PhysicalDevice, &count, null);
        const queues = try temp.alloc(c.VkQueueFamilyProperties, count);
        getProperties(c.g_PhysicalDevice, &count, queues.ptr);

        for (queues) |queue, i| {
            const mask = queue.queueFlags & c.VK_QUEUE_GRAPHICS_BIT;
            if (mask != 0) {
                break :queue_family std.math.cast(u32, i) catch @panic("rippo");
            }
        }

        @panic("couldn't get queue family");
    };

    // Create Logical Device (with 1 queue)
    {
        const device_extensions = [_]cstr{"VK_KHR_swapchain"};
        const queue_priority = [_]f32{1.0};
        var queue_info = [_]c.VkDeviceQueueCreateInfo{
            .{
                .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
                .queueFamilyIndex = c.g_QueueFamily,
                .queueCount = 1,
                .pQueuePriorities = &queue_priority,
                .pNext = null,
                .flags = 0,
            },
        };

        var create_info = c.VkDeviceCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
            .queueCreateInfoCount = queue_info.len,
            .pQueueCreateInfos = &queue_info,
            .enabledExtensionCount = device_extensions.len,
            .ppEnabledExtensionNames = &device_extensions,
            .pNext = null,
            .flags = 0,
            .enabledLayerCount = 0,
            .ppEnabledLayerNames = null,
            .pEnabledFeatures = null,
        };

        err = c.vkCreateDevice(c.g_PhysicalDevice, &create_info, null, &c.g_Device);
        checkVkResult(err);

        c.vkGetDeviceQueue(c.g_Device, c.g_QueueFamily, 0, &c.g_Queue);
    }

    c.cpp_SetupVulkan();
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

        try app.run();

        c.igRender();

        const draw_data = c.igGetDrawData();
        const display_size = draw_data.*.DisplaySize;
        const is_minimized = display_size.x <= 0.0 or display_size.y <= 0.0;
        if (!is_minimized) {
            rebuild_chain = c.cpp_render(handle, draw_data, app.clear_color);
        }

        std.time.sleep(14 * 1000 * 1000);
    }

    c.cpp_teardown(handle);
}
