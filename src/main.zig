const std = @import("std");
const render = @import("render/mod.zig");

pub extern "C" fn cpp_main() c_int;

pub fn main() void {
    const result = cpp_main();
    if (result != 0) {
        @panic("rippo bro");
    }
}
