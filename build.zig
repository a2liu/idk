const std = @import("std");

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

    // exe.linkLibCpp();
    // exe.linkLibC();

    // exe.linkSystemLibrary("c");
    // exe.linkSystemLibrary("glfw");
    // exe.linkSystemLibrary("epoxy");

    exe.addIncludeDir("src/gui/include");
    exe.addCSourceFiles(&.{
        "src/gui/imgui.cpp",
        "src/gui/imgui_draw.cpp",
        "src/gui/imgui_widgets.cpp",
        "src/gui/imgui_tables.cpp",
        "src/gui/imgui_demo.cpp",

        "src/gui/cimgui.cpp",
    }, &.{
        "-fno-exceptions",
        "-fno-rtti",
        "-Wno-return-type-c-linkage",
    });

    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

// helper function to get SDK path on Mac
fn macosFrameworksDir(b: *std.build.Builder) ![]u8 {
    var str = try b.exec(&[_][]const u8{ "xcrun", "--show-sdk-path" });
    const strip_newline = std.mem.lastIndexOf(u8, str, "\n");
    if (strip_newline) |index| {
        str = str[0..index];
    }
    const frameworks_dir = try std.mem.concat(b.allocator, u8, &[_][]const u8{ str, "/System/Library/Frameworks" });
    return frameworks_dir;
}
