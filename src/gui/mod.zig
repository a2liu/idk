const glfw = @import("glfw");
const vk = @import("vulkan");
const c = @import("../c.zig");

const Key = glfw.Key;

pub fn init(extent: vk.Extent2D) !void {
    var ctx = c.igCreateContext(null);
    c.igSetCurrentContext(ctx);

    // Setup back-end capabilities flags
    var io = c.igGetIO();
    io.*.IniFilename = null;

    // Sensible memory-friendly initial mouse position.
    io.*.MousePos = .{ .x = 0, .y = 0 };
    io.*.DisplaySize = c.ImVec2{
        .x = @intToFloat(f32, extent.width),
        .y = @intToFloat(f32, extent.height),
    };

    // io.*.ConfigFlags |=c.ImGuiConfigFlags_DockingEnable;
    // io.*.ConfigFlags |=c.ImGuiConfigFlags_ViewportsEnable;
    // io.*.ConfigDockingWithShift = true;

    inline for (key_mappings) |mapping| {
        const target = mapping.@"0";
        const enum_value = mapping.@"1";

        io.*.KeyMap[target] = @enumToInt(enum_value);
    }

    var w: i32 = undefined;
    var h: i32 = undefined;
    var bytes_per_pixel: i32 = undefined;
    var pixels: [*c]u8 = undefined;

    c.ImFontAtlas_GetTexDataAsRGBA32(io.*.Fonts, &pixels, &w, &h, &bytes_per_pixel);

    // const font_tex = gfx.Texture.initWithData(u8, w, h, pixels[0..@intCast(usize, w * h * bytes_per_pixel)]);
    // c.igImFontAtlas_SetTexID(io.Fonts, font_tex.imTextureID());
}

const key_mappings = .{
    .{ c.ImGuiKey_Tab, Key.tab },
    .{ c.ImGuiKey_Home, Key.home },
    .{ c.ImGuiKey_Insert, Key.insert },
    .{ c.ImGuiKey_KeypadEnter, Key.kp_enter },
    .{ c.ImGuiKey_Escape, Key.escape },
    .{ c.ImGuiKey_Backspace, Key.backspace },
    .{ c.ImGuiKey_End, Key.end },
    .{ c.ImGuiKey_Enter, Key.enter },

    .{ c.ImGuiKey_LeftArrow, Key.left },
    .{ c.ImGuiKey_RightArrow, Key.right },
    .{ c.ImGuiKey_UpArrow, Key.up },
    .{ c.ImGuiKey_DownArrow, Key.down },

    .{ c.ImGuiKey_PageUp, Key.page_up },
    .{ c.ImGuiKey_PageDown, Key.page_down },
    .{ c.ImGuiKey_Space, Key.space },

    .{ c.ImGuiKey_A, Key.a },
    .{ c.ImGuiKey_B, Key.b },
    .{ c.ImGuiKey_C, Key.c },
    .{ c.ImGuiKey_D, Key.d },
    .{ c.ImGuiKey_E, Key.e },
    .{ c.ImGuiKey_F, Key.f },
    .{ c.ImGuiKey_G, Key.g },
    .{ c.ImGuiKey_H, Key.h },
    .{ c.ImGuiKey_I, Key.i },
    .{ c.ImGuiKey_J, Key.j },
    .{ c.ImGuiKey_K, Key.k },
    .{ c.ImGuiKey_L, Key.l },
    .{ c.ImGuiKey_M, Key.m },
    .{ c.ImGuiKey_N, Key.n },
    .{ c.ImGuiKey_O, Key.o },
    .{ c.ImGuiKey_P, Key.p },
    .{ c.ImGuiKey_Q, Key.q },
    .{ c.ImGuiKey_R, Key.r },
    .{ c.ImGuiKey_S, Key.s },
    .{ c.ImGuiKey_T, Key.t },
    .{ c.ImGuiKey_U, Key.u },
    .{ c.ImGuiKey_V, Key.v },
    .{ c.ImGuiKey_W, Key.w },
    .{ c.ImGuiKey_X, Key.x },
    .{ c.ImGuiKey_Y, Key.y },
    .{ c.ImGuiKey_Z, Key.z },

    .{ c.ImGuiKey_0, Key.zero },
    .{ c.ImGuiKey_1, Key.one },
    .{ c.ImGuiKey_2, Key.two },
    .{ c.ImGuiKey_3, Key.three },
    .{ c.ImGuiKey_4, Key.four },
    .{ c.ImGuiKey_5, Key.five },
    .{ c.ImGuiKey_6, Key.six },
    .{ c.ImGuiKey_7, Key.seven },
    .{ c.ImGuiKey_8, Key.eight },
    .{ c.ImGuiKey_9, Key.nine },

    .{ c.ImGuiKey_Keypad0, Key.kp_0 },
    .{ c.ImGuiKey_Keypad1, Key.kp_1 },
    .{ c.ImGuiKey_Keypad2, Key.kp_2 },
    .{ c.ImGuiKey_Keypad3, Key.kp_3 },
    .{ c.ImGuiKey_Keypad4, Key.kp_4 },
    .{ c.ImGuiKey_Keypad5, Key.kp_5 },
    .{ c.ImGuiKey_Keypad6, Key.kp_6 },
    .{ c.ImGuiKey_Keypad7, Key.kp_7 },
    .{ c.ImGuiKey_Keypad8, Key.kp_8 },
    .{ c.ImGuiKey_Keypad9, Key.kp_9 },
};
