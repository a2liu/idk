const std = @import("std");
const alloc = @import("allocators.zig");
const gui = @import("gui.zig");
const c = @import("c.zig");

const ArrayList = std.ArrayList;

const TodoItem = struct {
    is_done: bool = false,
    name: ArrayList(u8) = ArrayList(u8).init(alloc.Global),
};

// Globals are safe here, because we only run the GUI code on exactly one
// thread.
var items = ArrayList(TodoItem).init(alloc.Global);

pub fn todoApp(is_open: *bool) void {
    _ = c.igBegin("Todo App", is_open, 0);
    defer c.igEnd();

    gui.Text(
        "Hello world!",
        .{},
    );
}
