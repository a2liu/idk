const std = @import("std");
const liu = @import("liu");
const gui = @import("gui.zig");
const c = @import("c.zig");

const cast = std.math.cast;
const ArrayList = std.ArrayList;

const TodoItem = struct {
    is_done: bool = false,
    id: c_int,
    name: ArrayList(u8) = ArrayList(u8).init(liu.Alloc),
};

// Globals are safe here, because we only run the GUI code on exactly one
// thread.
var next_id: c_int = 0;
var items = ArrayList(TodoItem).init(liu.Alloc);

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

    // if (ImGui::BeginTable("table_advanced", 6, flags, outer_size_enabled ? outer_size_value : ImVec2(0, 0), inner_width_to_use))

    const ColSpec = struct {
        label: [:0]const u8,
        flags: c.ImGuiTableFlags = 0,
        init_width_or_weight: f32 = 0,
    };

    const columns = .{
        ColSpec{
            .label = "is_done",
            .flags = c.ImGuiTableColumnFlags_WidthFixed | c.ImGuiTableColumnFlags_NoHide,
            .init_width_or_weight = 20,
        },
        ColSpec{
            .label = "name",
            .flags = c.ImGuiTableColumnFlags_WidthStretch,
        },
    };
    const table_flags = c.ImGuiTableFlags_Resizable | c.ImGuiTableFlags_Reorderable | c.ImGuiTableFlags_RowBg | c.ImGuiTableFlags_Borders | c.ImGuiTableFlags_NoBordersInBody | c.ImGuiTableFlags_ScrollY | c.ImGuiTableFlags_SizingFixedFit;
    const size = .{ .x = 0, .y = 0 };

    if (c.igBeginTable("##table", columns.len, table_flags, size, 0.0)) {
        defer c.igEndTable();

        inline for (columns) |col| {
            c.igTableSetupColumn(col.label, col.flags, col.init_width_or_weight, 0);
        }

        var text_col_width: f32 = 0;
        for (items.items) |*item| {
            c.igPushID_Int(item.id);

            // checkbox
            if (c.igTableNextColumn()) {
                _ = c.igCheckbox("##is_done", &item.is_done);
            }

            // text
            if (c.igTableNextColumn()) {
                if (text_col_width == 0) {
                    var region: c.ImVec2 = undefined;
                    c.igGetContentRegionAvail(&region);
                    text_col_width = region.x;
                }

                const flags = c.ImGuiInputTextFlags_CallbackResize;
                const name = &item.name;

                c.igPushItemWidth(text_col_width);

                // @Safety the textCallback here uses the C calling convention,
                // but I am unsure which calling convention imgui accepts for
                // its callbacks.
                _ = c.igInputText(
                    "##name",
                    name.items.ptr,
                    name.capacity,
                    flags,
                    textCallback,
                    name,
                );

                c.igPopItemWidth();
            }

            c.igPopID();
        }
    }
}
