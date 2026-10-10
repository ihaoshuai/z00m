const std = @import("std");

const DesktopEnv = enum {
    Wayland, X11
};

const LinuxSystemOs = enum {
    Fedora
};

const curDesktopEnv = DesktopEnv.X11;
const curOs = LinuxSystemOs.Fedora;


pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // raylib dep
    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
        .linux_display_backend = .X11,
    });
    const raylib = raylib_dep.module("raylib"); // main raylib module
    const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library



    // 直接创建可执行文件
    const exe = b.addExecutable(.{
        .name = "z00m",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // link to raylib
    exe.root_module.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);

    const os_tag = target.result.os.tag;
    if (os_tag == .linux and curDesktopEnv == DesktopEnv.X11 ) {
        exe.root_module.link_libc = true;
        exe.root_module.linkSystemLibrary("X11", .{});        
    }



    b.installArtifact(exe);

    // 配置 `zig build run`
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run z00m");
    run_step.dependOn(&run_cmd.step);
}