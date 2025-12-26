const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const upstream = b.dependency("sdl_net", .{});
    const lib = b.addLibrary(.{
        .name = "sdl_net",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    lib.root_module.addCSourceFile(.{ .file = upstream.path("src/SDL_net.c") });
    lib.root_module.addIncludePath(upstream.path("include"));
    lib.installHeadersDirectory(upstream.path("include/SDL3_net"), "SDL3_net", .{});

    const sdl_dep = b.dependency("sdl", .{
        .target = target,
        .optimize = optimize,
    });
    lib.root_module.linkLibrary(sdl_dep.artifact("SDL3"));

    b.installArtifact(lib);
}
