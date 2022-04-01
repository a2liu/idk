pub const raw = @cImport({
    @cUndef("__cplusplus");
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", "1");
    @cInclude("cimgui.h");
});

const type_info = @typeInfo(raw);
