const std = @import("std");
const alloc = @import("allocators.zig");
const gui = @import("gui.zig");
const c = @import("c.zig");

const cast = std.math.cast;
const ArrayList = std.ArrayList;

const TodoItem = struct {
    is_done: bool = false,
    name: ArrayList(u8) = ArrayList(u8).init(alloc.Global),
};

// Globals are safe here, because we only run the GUI code on exactly one
// thread.
var items = ArrayList(TodoItem).init(alloc.Global);

fn textCallback(data: [*c]c.ImGuiInputTextCallbackData) callconv(.C) c_int {
    _ = data;

    // https://github.com/ocornut/imgui/blob/master/misc/cpp/imgui_stdlib.cpp
    // https://github.com/ocornut/imgui/blob/1ba2905017ea81545b2fd1d45fee093a4982d9b1/imgui.h#L2071

    return 0;
}

pub fn todoApp(is_open: *bool) !void {
    c.igSetNextWindowSize(.{ .x = 300, .y = 400 }, c.ImGuiCond_FirstUseEver);

    _ = c.igBegin("Todo App", is_open, 0);
    defer c.igEnd();

    if (c.igButton("Add a todo item", .{ .x = 0, .y = 0 })) {
        var newItem = TodoItem{};
        try newItem.name.ensureUnusedCapacity(64);

        const allocated = newItem.name.allocatedSlice();
        @memset(allocated.ptr, 0, allocated.len);

        try items.append(newItem);
    }

    for (items.items) |item, index| {
        var name = item.name;

        c.igPushID_Int(cast(c_int, index) catch @panic("wtf"));

        _ = c.igInputText(
            "##",
            name.items.ptr,
            name.capacity,
            0,
            textCallback,
            &name,
        );

        c.igPopID();
    }
}
