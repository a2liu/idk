const std = @import("std");
const alloc = @import("allocators.zig");
const gui = @import("gui.zig");
const c = @import("c.zig");

const cast = std.math.cast;
const ArrayList = std.ArrayList;

const TodoItem = struct {
    is_done: bool = false,
    id: c_int,
    name: ArrayList(u8) = ArrayList(u8).init(alloc.Global),
};

// Globals are safe here, because we only run the GUI code on exactly one
// thread.
var next_id: c_int = 0;
var items = ArrayList(TodoItem).init(alloc.Global);

fn textCallback(data: [*c]c.ImGuiInputTextCallbackData) callconv(.C) c_int {
    const aligned_user_data = @alignCast(8, data.*.UserData);
    const name = @ptrCast(*ArrayList(u8), aligned_user_data);

    if (data.*.EventFlag == c.ImGuiInputTextFlags_CallbackResize) {
        std.debug.assert(data.*.Buf == name.items.ptr);

        // Resize string callback
        // If for some reason we refuse the new length (BufTextLen) and/or capacity (BufSize) we need to set them back to what we want.
        const len = cast(usize, data.*.BufTextLen) catch @panic("oops");
        name.resize(len) catch @panic("welp");
        data.*.Buf = name.items.ptr;
    }

    return 0;
}

pub fn todoApp(is_open: *bool) !void {
    c.igSetNextWindowSize(.{ .x = 400, .y = 400 }, c.ImGuiCond_FirstUseEver);

    _ = c.igBegin("Todo App", is_open, 0);
    defer c.igEnd();

    if (!is_open.*) {
        std.debug.print("closing from window\n", .{});

        for (items.items) |*item| {
            item.name.deinit();
        }

        items.items.len = 0;

        return;
    }

    if (c.igButton("Add a todo item", .{ .x = 0, .y = 0 })) {
        var newItem = TodoItem{ .id = next_id };
        next_id += 1;

        try newItem.name.resize(64);
        newItem.name.items[0] = 0;

        try items.append(newItem);
    }

    const flags = c.ImGuiInputTextFlags_CallbackResize;

    for (items.items) |*item| {
        const name = &item.name;

        c.igPushID_Int(item.id);

        _ = c.igInputText(
            "##",
            name.items.ptr,
            name.capacity,
            flags,
            textCallback,
            name,
        );

        c.igPopID();
    }
}
