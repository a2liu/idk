const std = @import("std");

usingnamespace raw;
const raw = @cImport({
    @cUndef("__cplusplus");
    @cInclude("vulkan/vulkan.h");

    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", "1");
    @cInclude("cimgui.h");

    @cDefine("IMGUI_IMPL_API", "");
    @cDefine("NULL", "((void*) 0)");
    @cInclude("imgui_impl_render.h");
    @cInclude("imgui_impl_platform.h");
});

pub const str_z = [*:0]const u8;
pub const str = [*c]const u8;

pub fn vkErr(err: raw.VkResult) callconv(.C) void {
    if (err == 0) return;

    std.debug.print("[vulkan] Error: VkResult = {}\n", .{err});
    if (err < 0)
        @panic("[vulkan] aborted");
}
