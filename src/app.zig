const std = @import("std");
const alloc = @import("./allocators.zig");
const glfw = @import("glfw");
const gui = @import("gui.zig");
const render = @import("render/mod.zig");
const c = @import("c.zig");

const todoApp = @import("todo.zig").todoApp;

pub const AppState = struct {
    demo: bool = true,
    todo: bool = true,

    float_value: f32 = 0.0,
    counter_value: i32 = 0,
    clear_color: c.ImVec4 = .{ .x = 0.45, .y = 0.55, .z = 0.60, .w = 1.00 },

    computeDelta: f32 = 0,
    frameDelta: f32 = 0,
};

fn navigator(state: *AppState) void {
    const pivot = .{ .x = 0, .y = 0 };
    c.igSetNextWindowPos(.{ .x = 0, .y = 0 }, c.ImGuiCond_FirstUseEver, pivot);

    // Create a window called "Hello, world!" and append into it.
    _ = c.igBegin("Hello, world!", null, 0);
    defer c.igEnd();

    // Display some text (you can use a format strings too)
    gui.Text("This is some useful text.", .{});

    // Edit bools storing our window open/close state
    _ = c.igCheckbox("Demo Window", &state.demo);
    _ = c.igCheckbox("Todo App", &state.todo);

    // Edit 1 float using a slider from 0.0f to 1.0f
    // return value is whether value changed
    _ = c.igSliderFloat("float", &state.float_value, 0.0, 1.0, "%.3f", 0);

    // Edit 3 floats representing a color
    _ = c.igColorEdit3("clear color", @ptrCast(*f32, &state.clear_color), 0);

    // Buttons return true when clicked (most widgets return true when
    // edited/activated)
    if (c.igButton("Button", .{ .x = 0, .y = 0 })) {
        state.counter_value += 1;
    }

    c.igSameLine(0.0, -1.0);
    gui.Text("counter = {}", .{state.counter_value});

    {
        const io: [*c]c.ImGuiIO = c.igGetIO();
        const fps = io.*.Framerate;
        const frame_time = 1000.0 / fps;
        gui.Text(
            "ImGui average {d:.3} ms/frame ({d:.1} FPS)",
            .{ frame_time, fps },
        );
    }

    {
        const frame_time = state.frameDelta;
        const fps = 1000.0 / frame_time;

        gui.Text(
            "Frame average {d:.3} ms/frame ({d:.1} FPS)",
            .{ frame_time, fps },
        );
    }

    {
        const frame_time = state.computeDelta;
        const fps = 1000.0 / frame_time;

        gui.Text(
            "Compute average {d:.3} ms/frame ({d:.1} FPS)",
            .{ frame_time, fps },
        );
    }
}

pub fn run(state: *AppState) !void {
    navigator(state);

    if (state.demo) {
        c.igShowDemoWindow(&state.demo);
    }

    if (state.todo) {
        const pivot = .{ .x = 0, .y = 0 };
        const point = .{ .x = 200, .y = 250 };
        c.igSetNextWindowPos(point, c.ImGuiCond_FirstUseEver, pivot);
        try todoApp(&state.todo);
    }
}
