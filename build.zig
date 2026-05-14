const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const preferred_linkage = b.option(
        std.builtin.LinkMode,
        "preferred_linkage",
        "Prefer building statically or dynamically linked libraries (default: static)",
    ) orelse .static;

    var system_include_path = b.option(
        std.Build.LazyPath,
        "system_include_path",
        "System header search path for cross-compiling",
    );

    const build_sdl = b.option(
        bool,
        "build_sdl",
        "Also build and link SDL itself (default: false)",
    ) orelse false;

    const upstream = b.dependency("sdl_net", .{});
    const lib = b.addLibrary(.{
        .name = "SDL3_net",
        .linkage = preferred_linkage,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    const sdl_dep = b.dependency("sdl", .{
        .target = target,
        .optimize = optimize,
        .preferred_linkage = preferred_linkage,
        .system_include_path = system_include_path,
    });

    if (build_sdl) {
        lib.root_module.linkLibrary(sdl_dep.artifact("SDL3"));
        lib.installHeadersDirectory(sdl_dep.path("include/SDL3"), "SDL3", .{});
    } else lib.root_module.addIncludePath(sdl_dep.path("include"));

    switch (target.result.os.tag) {
        .windows => {
            lib.root_module.linkSystemLibrary("iphlpapi", .{});
            lib.root_module.linkSystemLibrary("ws2_32", .{});
        },
        .emscripten, .macos => {
            if (b.sysroot) |sysroot| {
                system_include_path = system_include_path orelse .{ .cwd_relative = b.pathJoin(&.{ sysroot, "include" }) };
            }
        },
        else => {},
    }

    lib.root_module.addCSourceFile(.{ .file = upstream.path("src/SDL_net.c") });
    lib.root_module.addIncludePath(upstream.path("include"));
    lib.installHeadersDirectory(upstream.path("include/SDL3_net"), "SDL3_net", .{});

    if (system_include_path) |path| {
        lib.root_module.addSystemIncludePath(path);
    }

    if (lib.linkage.? == .dynamic) {
        lib.setVersionScript(upstream.path("src/SDL_net.sym"));
        if (target.result.os.tag == .windows) {
            lib.root_module.addWin32ResourceFile(.{ .file = upstream.path("src/version.rc") });
        }
    }

    b.installArtifact(lib);

    // Add run steps for the examples.
    const examples = .{
        "voipchat",
        "simple-http-get",
        "resolve-hostnames",
        "get-local-addrs",
        "echo-server",
    };
    inline for (examples) |name| {
        const example = b.addExecutable(.{
            .name = name,
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            }),
        });
        example.root_module.linkLibrary(sdl_dep.artifact("SDL3"));
        example.root_module.linkLibrary(lib);
        example.root_module.addIncludePath(upstream.path("include"));
        example.root_module.addCSourceFiles(.{
            .root = upstream.path("examples"),
            .files = &.{name ++ ".c"},
        });
        const run_example = b.addRunArtifact(example);
        const run_step = b.step(name, "Run the " ++ name ++ " example");
        run_step.dependOn(&run_example.step);
    }
}
