usingnamespace @cImport({
    @cUndef("__cplusplus");
    @cInclude("vulkan/vulkan.h");

    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", "1");
    @cInclude("cimgui.h");

    @cDefine("IMGUI_IMPL_API", "");
    @cDefine("NULL", "((void*) 0)");
    @cInclude("imgui_impl_render.h");
    @cInclude("imgui_impl_platform.h");
});
