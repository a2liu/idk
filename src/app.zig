const std = @import("std");
const liu = @import("liu");
const glfw = @import("glfw");
const c = @import("c.zig");

pub fn Text(comptime format: []const u8, args: anytype) void {
    var _temp = liu.Temp.init();
    const temp = _temp.allocator();
    defer _temp.deinit();

    const allocResult = std.fmt.allocPrint(temp, format, args);
    const s = allocResult catch @panic("failed to print");
    c.igTextUnformatted(s.ptr, s.ptr + s.len);
}

pub const AppState = struct {
    computeDelta: f32 = 0,
    frameDelta: f32 = 0,
    clear_color: c.ImVec4 = .{ .x = 0.45, .y = 0.55, .z = 0.60, .w = 1.00 },
};

pub fn run(state: *AppState) !void {
    _ = state;

    const pivot = .{ .x = 0, .y = 0 };
    c.igSetNextWindowPos(.{ .x = 0, .y = 0 }, c.ImGuiCond_FirstUseEver, pivot);

    c.igSetNextWindowSizeConstraints(
        .{ .x = 300, .y = 400 },
        .{ .x = 600, .y = 500 },
        null,
        null,
    );

    // Create a window called "Hello, world!" and append into it.
    _ = c.igBegin("Hello, world!", null, 0);
    defer c.igEnd();

    // Edit 3 floats representing a color
    _ = c.igColorEdit3("clear color", @ptrCast(*f32, &state.clear_color), 0);
}
