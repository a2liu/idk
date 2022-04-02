const glfw = @import("glfw");
const Key = glfw.Key;

const ig = @cImport({
    @cUndef("__cplusplus");
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", "1");
    @cInclude("cimgui.h");
});

usingnamespace ig;

const key_mappings = .{
    .{ ig.ImGuiKey_Tab, Key.tab },
    .{ ig.ImGuiKey_Home, Key.home },
    .{ ig.ImGuiKey_Insert, Key.insert },
    .{ ig.ImGuiKey_KeypadEnter, Key.kp_enter },
    .{ ig.ImGuiKey_Escape, Key.escape },
    .{ ig.ImGuiKey_Backspace, Key.backspace },
    .{ ig.ImGuiKey_End, Key.end },
    .{ ig.ImGuiKey_Enter, Key.enter },

    .{ ig.ImGuiKey_LeftArrow, Key.left },
    .{ ig.ImGuiKey_RightArrow, Key.right },
    .{ ig.ImGuiKey_UpArrow, Key.up },
    .{ ig.ImGuiKey_DownArrow, Key.down },

    .{ ig.ImGuiKey_PageUp, Key.page_up },
    .{ ig.ImGuiKey_PageDown, Key.page_down },
    .{ ig.ImGuiKey_Space, Key.space },

    .{ ig.ImGuiKey_A, Key.a },
    .{ ig.ImGuiKey_B, Key.b },
    .{ ig.ImGuiKey_C, Key.c },
    .{ ig.ImGuiKey_D, Key.d },
    .{ ig.ImGuiKey_E, Key.e },
    .{ ig.ImGuiKey_F, Key.f },
    .{ ig.ImGuiKey_G, Key.g },
    .{ ig.ImGuiKey_H, Key.h },
    .{ ig.ImGuiKey_I, Key.i },
    .{ ig.ImGuiKey_J, Key.j },
    .{ ig.ImGuiKey_K, Key.k },
    .{ ig.ImGuiKey_L, Key.l },
    .{ ig.ImGuiKey_M, Key.m },
    .{ ig.ImGuiKey_N, Key.n },
    .{ ig.ImGuiKey_O, Key.o },
    .{ ig.ImGuiKey_P, Key.p },
    .{ ig.ImGuiKey_Q, Key.q },
    .{ ig.ImGuiKey_R, Key.r },
    .{ ig.ImGuiKey_S, Key.s },
    .{ ig.ImGuiKey_T, Key.t },
    .{ ig.ImGuiKey_U, Key.u },
    .{ ig.ImGuiKey_V, Key.v },
    .{ ig.ImGuiKey_W, Key.w },
    .{ ig.ImGuiKey_X, Key.x },
    .{ ig.ImGuiKey_Y, Key.y },
    .{ ig.ImGuiKey_Z, Key.z },

    .{ ig.ImGuiKey_0, Key.zero },
    .{ ig.ImGuiKey_1, Key.one },
    .{ ig.ImGuiKey_2, Key.two },
    .{ ig.ImGuiKey_3, Key.three },
    .{ ig.ImGuiKey_4, Key.four },
    .{ ig.ImGuiKey_5, Key.five },
    .{ ig.ImGuiKey_6, Key.six },
    .{ ig.ImGuiKey_7, Key.seven },
    .{ ig.ImGuiKey_8, Key.eight },
    .{ ig.ImGuiKey_9, Key.nine },

    .{ ig.ImGuiKey_Keypad0, Key.kp_0 },
    .{ ig.ImGuiKey_Keypad1, Key.kp_1 },
    .{ ig.ImGuiKey_Keypad2, Key.kp_2 },
    .{ ig.ImGuiKey_Keypad3, Key.kp_3 },
    .{ ig.ImGuiKey_Keypad4, Key.kp_4 },
    .{ ig.ImGuiKey_Keypad5, Key.kp_5 },
    .{ ig.ImGuiKey_Keypad6, Key.kp_6 },
    .{ ig.ImGuiKey_Keypad7, Key.kp_7 },
    .{ ig.ImGuiKey_Keypad8, Key.kp_8 },
    .{ ig.ImGuiKey_Keypad9, Key.kp_9 },
};

pub fn init() !void {
    var ctx = ig.igCreateContext(null);
    ig.igSetCurrentContext(ctx);

    // Setup back-end capabilities flags
    var io = ig.igGetIO();
    io.*.BackendRendererName = "imgui_impl_vulkan";
    // Sensible memory-friendly initial mouse position.
    io.*.MousePos = .{ .x = 0, .y = 0 };

    inline for (key_mappings) |mapping| {
        const target = mapping.@"0";
        const enum_value = mapping.@"1";

        io.*.KeyMap[target] = @enumToInt(enum_value);
    }
}
