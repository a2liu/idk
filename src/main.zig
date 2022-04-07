const std = @import("std");
const alloc = @import("./allocators.zig");
const glfw = @import("glfw");
const gui = @import("gui.zig");
const render = @import("render/mod.zig");
const c = @import("c.zig");
const app = @import("app.zig");

// This file mostly contains plumbing to get this app to work.
const app_name = "Dear ImGui GLFW+Vulkan example";
const cstr = [*c]const u8;

fn checkVkResult(err: c.VkResult) callconv(.C) void {
    if (err == 0) return;

    std.debug.print("[vulkan] Error: VkResult = {}\n", .{err});
    if (err < 0)
        @panic("[vulkan] aborted");
}

// This maybe *should* have VKAPI_ATTR or VKAPI_CALL in there, but they're C
// macros. Unsure where they go here.
//                              - Albert Liu, Apr 06, 2022 Wed 23:58 EDT
fn debug_report(
    flags: c.VkDebugReportFlagsEXT,
    objectType: c.VkDebugReportObjectTypeEXT,
    object: u64,
    location: usize,
    messageCode: i32,
    pLayerPrefix: cstr,
    pMessage: cstr,
    pUserData: ?*anyopaque,
) callconv(.C) c.VkBool32 {
    _ = flags;
    _ = object;
    _ = location;
    _ = messageCode;
    _ = pLayerPrefix;
    _ = pUserData;

    const fmt = "[vulkan] Debug report from ObjectType: {}\nMessage: {s}\n\n";
    std.debug.print(fmt, .{ objectType, pMessage });

    return c.VK_FALSE;
}

// All the ImGui_ImplVulkanH_XXX structures/functions are optional helpers used
// by the demo. Your real engine/app may not use them.
fn setupVulkan(window: *c.GLFWwindow, width: c_int, height: c_int) !void {
    var _temp = alloc.Temp.init();
    const temp = _temp.allocator();
    defer _temp.deinit();

    var err: c.VkResult = undefined;

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
            const name = "vkCreateDebugReportCallbackEXT";
            const raw_callback = c.vkGetInstanceProcAddr(c.g_Instance, name);
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
            .pfnCallback = debug_report,
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

            if (properties.deviceType != c.VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU)
                continue;

            break :select_gpu gpu;
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

    {
        const pool_sizes = [_]c.VkDescriptorPoolSize{
            .{ .@"type" = c.VK_DESCRIPTOR_TYPE_SAMPLER, .descriptorCount = 1000 },
            .{ .@"type" = c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, .descriptorCount = 1000 },
            .{ .@"type" = c.VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE, .descriptorCount = 1000 },
            .{ .@"type" = c.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, .descriptorCount = 1000 },
            .{ .@"type" = c.VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER, .descriptorCount = 1000 },
            .{ .@"type" = c.VK_DESCRIPTOR_TYPE_STORAGE_TEXEL_BUFFER, .descriptorCount = 1000 },
            .{ .@"type" = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, .descriptorCount = 1000 },
            .{ .@"type" = c.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, .descriptorCount = 1000 },
            .{ .@"type" = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC, .descriptorCount = 1000 },
            .{ .@"type" = c.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER_DYNAMIC, .descriptorCount = 1000 },
            .{ .@"type" = c.VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT, .descriptorCount = 1000 },
        };

        const pool_info = c.VkDescriptorPoolCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
            .flags = c.VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT,
            .maxSets = 1000 * pool_sizes.len,
            .poolSizeCount = pool_sizes.len,
            .pPoolSizes = &pool_sizes,
            .pNext = null,
        };
        err = c.vkCreateDescriptorPool(c.g_Device, &pool_info, null, &c.g_DescriptorPool);
        checkVkResult(err);
    }

    const wd = &c.g_MainWindowData;

    {
        // Create Window Surface
        var surface: c.VkSurfaceKHR = undefined;
        err = c.glfwCreateWindowSurface(c.g_Instance, window, null, &surface);
        checkVkResult(err);

        // Create Framebuffers
        var w: c_int = undefined;
        var h: c_int = undefined;
        c.glfwGetFramebufferSize(window, &w, &h);

        wd.Surface = surface;

        // Check for WSI support
        var res: c.VkBool32 = undefined;
        _ = c.vkGetPhysicalDeviceSurfaceSupportKHR(c.g_PhysicalDevice, c.g_QueueFamily, wd.Surface, &res);
        if (res != c.VK_TRUE) {
            @panic("Error no WSI support on physical device 0\n");
        }

        const imageFormat = [_]c.VkFormat{
            c.VK_FORMAT_B8G8R8A8_UNORM, c.VK_FORMAT_R8G8B8A8_UNORM,
            c.VK_FORMAT_B8G8R8_UNORM,   c.VK_FORMAT_R8G8B8_UNORM,
        };
        const colorSpace = c.VK_COLORSPACE_SRGB_NONLINEAR_KHR;
        wd.SurfaceFormat = c.ImGui_ImplVulkanH_SelectSurfaceFormat(
            c.g_PhysicalDevice,
            wd.Surface,
            &imageFormat,
            imageFormat.len,
            colorSpace,
        );

        const present_modes = [_]c.VkPresentModeKHR{
            c.VK_PRESENT_MODE_MAILBOX_KHR, c.VK_PRESENT_MODE_IMMEDIATE_KHR,
            c.VK_PRESENT_MODE_FIFO_KHR,
        };
        wd.PresentMode = c.ImGui_ImplVulkanH_SelectPresentMode(c.g_PhysicalDevice, wd.Surface, &present_modes, present_modes.len);

        // Create SwapChain, RenderPass, Framebuffer, etc.
        c.ImGui_ImplVulkanH_CreateOrResizeWindow(c.g_Instance, c.g_PhysicalDevice, c.g_Device, wd, c.g_QueueFamily, null, width, height, 2);
    }

    // Setup Platform/Renderer backends
    {
        _ = c.ImGui_ImplGlfw_InitForVulkan(window, true);
        var init_info = c.ImGui_ImplVulkan_InitInfo{
            .Instance = c.g_Instance,
            .PhysicalDevice = c.g_PhysicalDevice,
            .Device = c.g_Device,
            .QueueFamily = c.g_QueueFamily,
            .Queue = c.g_Queue,
            .PipelineCache = null,
            .DescriptorPool = c.g_DescriptorPool,
            .Subpass = 0,
            .MinImageCount = 2,
            .ImageCount = wd.ImageCount,
            .MSAASamples = c.VK_SAMPLE_COUNT_1_BIT,
            .Allocator = null,
            .CheckVkResultFn = checkVkResult,
        };
        _ = c.ImGui_ImplVulkan_Init(&init_info, wd.RenderPass);
    }

    // Load Fonts
    // - If no fonts are loaded, dear imgui will use the default font. You can
    // also load multiple fonts and use ImGui::PushFont()/PopFont() to select
    // them.
    // - AddFontFromFileTTF() will return the ImFont* so you can store it if you
    // need to select the font among multiple.
    // - If the file cannot be loaded, the function will return NULL. Please
    // handle those errors in your application (e.g. use an assertion, or display
    // an error and quit).
    // - The fonts will be rasterized at a given size (w/ oversampling) and stored
    // into a texture when calling ImFontAtlas::Build()/GetTexDataAsXXXX(), which
    // ImGui_ImplXXXX_NewFrame below will call.
    // - Read 'docs/FONTS.md' for more instructions and details.
    // - Remember that in C/C++ if you want to include a backslash \ in a string
    // literal you need to write a double backslash \\ !
    // io.Fonts->AddFontDefault();
    // io.Fonts->AddFontFromFileTTF("../../misc/fonts/Roboto-Medium.ttf", 16.0f);
    // io.Fonts->AddFontFromFileTTF("../../misc/fonts/Cousine-Regular.ttf", 15.0f);
    // io.Fonts->AddFontFromFileTTF("../../misc/fonts/DroidSans.ttf", 16.0f);
    // io.Fonts->AddFontFromFileTTF("../../misc/fonts/ProggyTiny.ttf", 10.0f);
    // ImFont* font =
    // io.Fonts->AddFontFromFileTTF("c:\\Windows\\Fonts\\ArialUni.ttf", 18.0f,
    // NULL, io.Fonts->GetGlyphRangesJapanese()); IM_ASSERT(font != NULL);
    {

        // Use any command queue
        const frame = wd.Frames[wd.FrameIndex];
        const command_pool = frame.CommandPool;
        const command_buffer = frame.CommandBuffer;

        err = c.vkResetCommandPool(c.g_Device, command_pool, 0);
        checkVkResult(err);

        const begin_info = c.VkCommandBufferBeginInfo{
            .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
            .flags = c.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
            .pNext = null,
            .pInheritanceInfo = null,
        };
        err = c.vkBeginCommandBuffer(command_buffer, &begin_info);
        checkVkResult(err);

        _ = c.ImGui_ImplVulkan_CreateFontsTexture(command_buffer);

        const end_info = c.VkSubmitInfo{
            .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
            .commandBufferCount = 1,
            .pCommandBuffers = &command_buffer,
            .pNext = null,
            .waitSemaphoreCount = 0,
            .pWaitSemaphores = null,
            .signalSemaphoreCount = 0,
            .pSignalSemaphores = null,
            .pWaitDstStageMask = null,
        };
        err = c.vkEndCommandBuffer(command_buffer);
        checkVkResult(err);
        err = c.vkQueueSubmit(c.g_Queue, 1, &end_info, null);
        checkVkResult(err);

        err = c.vkDeviceWaitIdle(c.g_Device);
        checkVkResult(err);
        c.ImGui_ImplVulkan_DestroyFontUploadObjects();
    }
}

fn teardown() void {
    const err = c.vkDeviceWaitIdle(c.g_Device);
    checkVkResult(err);

    c.ImGui_ImplVulkan_Shutdown();
    c.ImGui_ImplGlfw_Shutdown();

    c.ImGui_ImplVulkanH_DestroyWindow(c.g_Instance, c.g_Device, &c.g_MainWindowData, null);

    c.vkDestroyDescriptorPool(c.g_Device, c.g_DescriptorPool, null);

    const callback = cb: {
        const name = "vkDestroyDebugReportCallbackEXT";
        const raw_callback = c.vkGetInstanceProcAddr(c.g_Instance, name);
        if (@ptrCast(c.PFN_vkDestroyDebugReportCallbackEXT, raw_callback)) |cb| {
            break :cb cb;
        }

        @panic("rip");
    };

    callback(c.g_Instance, c.g_DebugReport, null);

    c.vkDestroyDevice(c.g_Device, null);
    c.vkDestroyInstance(c.g_Instance, null);
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

    // Setup Dear ImGui context, return value is the context that's created
    _ = c.igCreateContext(null);
    defer c.igDestroyContext(null);

    {
        const io = c.igGetIO();
        io.*.IniFilename = null;
        c.igStyleColorsDark(null); // Setup Dear ImGui style
    }

    try setupVulkan(handle, width, height);

    // c.cpp_init(handle);

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

    teardown();
}
