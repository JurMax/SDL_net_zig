const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const preferred_linkage = b.option(
        std.builtin.LinkMode,
        "preferred_linkage",
        "Prefer building statically or dynamically linked libraries (default: static)",
    ) orelse .static;

    const upstream = b.dependency("sdl_net", .{});
    const lib = b.addLibrary(.{
        .name = "sdl_net",
        .linkage = preferred_linkage,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    lib.root_module.addCSourceFile(.{ .file = upstream.path("src/SDL_net.c") });
    lib.root_module.addIncludePath(upstream.path("include"));
    lib.installHeadersDirectory(upstream.path("include/SDL3_net"), "SDL3_net", .{});

    if (lib.linkage.? == .dynamic) {
        lib.setVersionScript(upstream.path("src/SDL_net.sym"));
        lib.linker_allow_undefined_version = true;
        if (target.result.os.tag == .windows) {
            lib.addWin32ResourceFile(.{ .file = upstream.path("src/version.rc") });
        }
    }

    const sdl_dep = b.dependency("sdl", .{
        .target = target,
        .optimize = optimize,
        .preferred_linkage = preferred_linkage,
    });
    lib.root_module.linkLibrary(sdl_dep.artifact("SDL3"));

    b.installArtifact(lib);
}
