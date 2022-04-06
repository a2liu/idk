const std = @import("std");
const alloc = @import("./allocators.zig");
const glfw = @import("glfw");
const gui = @import("gui.zig");
const render = @import("render/mod.zig");
const c = @import("c.zig");

const todoApp = @import("todo.zig").todoApp;

const OpenApps = struct {
    demo: bool = true,
    todo: bool = true,
};

var open_apps = OpenApps{};
var float_value: f32 = 0.0;
var counter_value: i32 = 0;
pub var clear_color = c.ImVec4{ .x = 0.45, .y = 0.55, .z = 0.60, .w = 1.00 };

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

pub fn run() !void {
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
}
