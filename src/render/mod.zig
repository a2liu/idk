const std = @import("std");

usingnamespace @cImport({
    @cUndef("__cplusplus");
    @cInclude("vulkan/vulkan.h");
});
