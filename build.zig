const std = @import("std");
const rlz = @import("raylib_zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.module("raylib");
    const raygui = raylib_dep.module("raygui");
    const raylib_artifact = raylib_dep.artifact("raylib");

    if (target.query.os_tag == .emscripten) {
        const emsdk = rlz.emsdk;
        
        // For WASM, we compile main.zig as a library
        const wasm = b.addLibrary(.{
            .name = "webrayz_wasm",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/main.zig"),
                .target = target,
                .optimize = optimize,
            }),
        });

        wasm.root_module.addImport("raylib", raylib);
        wasm.root_module.addImport("raygui", raygui);

        const install_dir: std.Build.InstallDir = .{ .custom = "web" };
        const emcc_flags = emsdk.emccDefaultFlags(b.allocator, .{ .optimize = optimize });
        const emcc_settings = emsdk.emccDefaultSettings(b.allocator, .{ .optimize = optimize });

        const emcc_step = emsdk.emccStep(b, raylib_artifact, wasm, .{
            .optimize = optimize,
            .flags = emcc_flags,
            .settings = emcc_settings,
            .install_dir = install_dir,
        });

        b.getInstallStep().dependOn(emcc_step);

        const html_filename = std.fmt.allocPrint(b.allocator, "{s}.html", .{wasm.name}) catch @panic("OOM");
        
        const run_step = b.step("run", "Run the app");
        const emrun_step = emsdk.emrunStep(
            b,
            b.getInstallPath(install_dir, html_filename),
            &.{},
        );
        emrun_step.dependOn(emcc_step);
        run_step.dependOn(emrun_step);

    } else {
        const mod = b.addModule("webrayz", .{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
        });

        const exe = b.addExecutable(.{
            .name = "webrayz",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/main.zig"),
                .target = target,
                .optimize = optimize,
                .imports = &.{
                    .{ .name = "webrayz", .module = mod },
                },
            }),
        });

        exe.linkLibrary(raylib_artifact);
        exe.root_module.addImport("raylib", raylib);
        exe.root_module.addImport("raygui", raygui);

        b.installArtifact(exe);

        const run_step = b.step("run", "Run the app");
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        run_step.dependOn(&run_cmd.step);
        
        // Tests
        const mod_tests = b.addTest(.{
            .root_module = mod,
        });
        const run_mod_tests = b.addRunArtifact(mod_tests);
        const exe_tests = b.addTest(.{
            .root_module = exe.root_module,
        });
        const run_exe_tests = b.addRunArtifact(exe_tests);
        const test_step = b.step("test", "Run tests");
        test_step.dependOn(&run_mod_tests.step);
        test_step.dependOn(&run_exe_tests.step);
    }
}