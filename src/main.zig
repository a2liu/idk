const std = @import("std");
const vk = @import("vulkan");
const glfw = @import("glfw");
const alloc = @import("allocators.zig");
const gui = @import("gui/mod.zig");
const render = @import("render/mod.zig");

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;

const app_name = render.app_name;
const GraphicsContext = render.GraphicsContext;
const Swapchain = render.Swapchain;
const Vertex = render.Vertex;

const createFramebuffers = render.createFramebuffers;
const destroyFramebuffers = render.destroyFramebuffers;
const destroyCommandBuffers = render.destroyCommandBuffers;
const createCommandBuffers = render.createCommandBuffers;

const vertex_data = [_]Vertex{
    .{ .pos = .{ 0, -0.5 }, .color = .{ 1, 0, 0 } },
    .{ .pos = .{ 0.5, 0.5 }, .color = .{ 0, 1, 0 } },
    .{ .pos = .{ -0.5, 0.5 }, .color = .{ 0, 0, 1 } },
};

pub fn main() anyerror!void {
    try glfw.init(.{});
    defer glfw.terminate();

    try gui.init();

    const vertices: []const Vertex = vertex_data[0..vertex_data.len];

    var extent = vk.Extent2D{ .width = 800, .height = 600 };

    const window = try glfw.Window.create(extent.width, extent.height, app_name, null, null, .{
        .client_api = .no_api,
    });
    defer window.destroy();

    const allocator = std.heap.page_allocator;

    var gc = try GraphicsContext.init(allocator, app_name, window);
    defer gc.deinit();

    std.debug.print("Using device: {s}\n", .{gc.deviceName()});

    var swapchain = try Swapchain.init(&gc, allocator, extent);
    defer swapchain.deinit();

    const pipeline_layout = try gc.vkd.createPipelineLayout(gc.dev, &.{
        .flags = .{},
        .set_layout_count = 0,
        .p_set_layouts = undefined,
        .push_constant_range_count = 0,
        .p_push_constant_ranges = undefined,
    }, null);
    defer gc.vkd.destroyPipelineLayout(gc.dev, pipeline_layout, null);

    const render_pass = try render.createRenderPass(&gc, swapchain);
    defer gc.vkd.destroyRenderPass(gc.dev, render_pass, null);

    var pipeline = try render.createPipeline(&gc, pipeline_layout, render_pass);
    defer gc.vkd.destroyPipeline(gc.dev, pipeline, null);

    var framebuffers = try createFramebuffers(&gc, allocator, render_pass, swapchain);
    defer destroyFramebuffers(&gc, allocator, framebuffers);

    const pool = try gc.vkd.createCommandPool(gc.dev, &.{
        .flags = .{},
        .queue_family_index = gc.graphics_queue.family,
    }, null);
    defer gc.vkd.destroyCommandPool(gc.dev, pool, null);

    const buffer = try gc.vkd.createBuffer(gc.dev, &.{
        .flags = .{},
        .size = @sizeOf(Vertex) * vertices.len,
        .usage = .{ .transfer_dst_bit = true, .vertex_buffer_bit = true },
        .sharing_mode = .exclusive,
        .queue_family_index_count = 0,
        .p_queue_family_indices = undefined,
    }, null);
    defer gc.vkd.destroyBuffer(gc.dev, buffer, null);

    const mem_reqs = gc.vkd.getBufferMemoryRequirements(gc.dev, buffer);
    const memory = try gc.allocate(mem_reqs, .{ .device_local_bit = true });
    defer gc.vkd.freeMemory(gc.dev, memory, null);

    try gc.vkd.bindBufferMemory(gc.dev, buffer, memory, 0);

    try render.uploadVertices(&gc, pool, buffer, vertices);

    var cmdbufs = try render.createCommandBuffers(
        &gc,
        pool,
        allocator,
        buffer,
        swapchain.extent,
        render_pass,
        pipeline,
        framebuffers,
        vertices,
    );
    defer render.destroyCommandBuffers(&gc, pool, allocator, cmdbufs);

    while (!window.shouldClose()) {
        try glfw.pollEvents();

        const cmdbuf = cmdbufs[swapchain.image_index];

        const state = swapchain.present(cmdbuf) catch |err| switch (err) {
            error.OutOfDateKHR => blk: {
                break :blk Swapchain.PresentState.suboptimal;
            },
            else => |narrow| {
                return narrow;
            },
        };

        if (state == .suboptimal) {
            const size = try window.getSize();
            extent.width = @intCast(u32, size.width);
            extent.height = @intCast(u32, size.height);
            try swapchain.recreate(extent);

            destroyFramebuffers(&gc, allocator, framebuffers);
            framebuffers = try createFramebuffers(&gc, allocator, render_pass, swapchain);

            destroyCommandBuffers(&gc, pool, allocator, cmdbufs);
            cmdbufs = try createCommandBuffers(
                &gc,
                pool,
                allocator,
                buffer,
                swapchain.extent,
                render_pass,
                pipeline,
                framebuffers,
                vertices,
            );
        }

        // Rendering
        // gui.igNewFrame();
        // gui.igRender();

        const draw_data = gui.igGetDrawData();
        _ = draw_data;

        // const is_minimized = (draw_data.*.DisplaySize.x <= 0.0 or draw_data.*.DisplaySize.y <= 0.0);
        // _ = is_minimized;

        // if (!is_minimized)
        // {
        //     wd.ClearValue.color.float32[0] = clear_color.x * clear_color.w;
        //     wd.ClearValue.color.float32[1] = clear_color.y * clear_color.w;
        //     wd.ClearValue.color.float32[2] = clear_color.z * clear_color.w;
        //     wd.ClearValue.color.float32[3] = clear_color.w;
        //     FrameRender(wd, draw_data);
        //     FramePresent(wd);
        // }

        // try render.uploadVertices(&gc, pool, buffer, draw_data);

        // if (gui.igSmallButton("Hello")) {
        //     std.debug.print("Hello world\n", .{});
        // }
    }

    try swapchain.waitForAllFences();
}

fn resize(
    gc: *GraphicsContext,
    pool: vk.CommandPool,
    allocator: Allocator,
    buffer: vk.Buffer,
    extent: *vk.Extent2D,
    render_pass: vk.RenderPass,
    pipeline: vk.Pipeline,
    framebuffers: []vk.Framebuffer,
    vertices: []const Vertex,
    window: glfw.Window,
    cmdbufs: *[]vk.CommandBuffer,
    swapchain: *Swapchain,
) !void {
    const cmdbuf = cmdbufs.*[swapchain.image_index];

    const state = swapchain.present(cmdbuf) catch |err| switch (err) {
        error.OutOfDateKHR => blk: {
            break :blk Swapchain.PresentState.suboptimal;
        },
        else => |narrow| {
            return narrow;
        },
    };

    if (state == .suboptimal) {
        const size = try window.getSize();
        extent.width = @intCast(u32, size.width);
        extent.height = @intCast(u32, size.height);
        try swapchain.recreate(extent);

        destroyFramebuffers(&gc, allocator, framebuffers);
        framebuffers = try createFramebuffers(&gc, allocator, render_pass, swapchain);

        destroyCommandBuffers(&gc, pool, allocator, cmdbufs);
        cmdbufs.* = try createCommandBuffers(
            &gc,
            pool,
            allocator,
            buffer,
            swapchain.extent,
            render_pass,
            pipeline,
            framebuffers,
            vertices,
        );
    }
}
