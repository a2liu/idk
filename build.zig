const std = @import("std");

const glfw = @import("libs/mach-glfw/build.zig");
const vkgen = @import("libs/vulkan-zig/generator/index.zig");
const zigvulkan = @import("libs/vulkan-zig/build.zig");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("idk", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    // TODO not currently used right now
    // vulkan-zig: Create a step that generates vk.zig (stored in zig-cache) from the provided vulkan registry.
    // const gen = vkgen.VkGenerateStep.init(b, "libs/vulkan-zig/examples/vk.xml", "vk.zig");
    // exe.addPackage(gen.package);

    // mach-glfw
    exe.addPackagePath("glfw", "libs/mach-glfw/src/main.zig");
    glfw.link(b, exe, .{});

    // shader resources, to be compiled using glslc
    const res = zigvulkan.ResourceGenStep.init(b, "shaders.zig");
    res.addShader("triangle_vert", "src/render/shader.vert");
    res.addShader("triangle_frag", "src/render/shader.frag");
    exe.addPackage(res.package);

    exe.linkLibCpp();
    exe.linkSystemLibrary("vulkan");

    exe.addIncludeDir("src/include");
    exe.addIncludeDir("libs/imgui/include");

    const files = .{
        "libs/imgui/cimgui.cpp",            "libs/imgui/imgui.cpp",
        "libs/imgui/imgui_draw.cpp",        "libs/imgui/imgui_widgets.cpp",
        "libs/imgui/imgui_tables.cpp",      "libs/imgui/imgui_demo.cpp",
        "libs/imgui/imgui_impl_render.cpp", "libs/imgui/imgui_impl_platform.cpp",

        "src/imgui_impl.cpp",
    };
    const flags = .{
        "-fno-exceptions", "-fno-rtti",   "-Wno-return-type-c-linkage",
        "-nostdlib",       "-nostdlib++",
    };
    exe.addCSourceFiles(&files, &flags);

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
