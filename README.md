
# SDL_net_zig

This is a port of [SDL3_net](https://github.com/libsdl-org/SDL_net) to the [Zig](https://ziglang.org/) build system.

## How to use it

### As a library

First, fetch this repository:

```sh
zig fetch --save git+https://github.com/JurMax/SDL_net_zig
```

Next, add it to your `build.zig`:

```zig
const sdl_net_dependency = b.dependency("sdl_net_zig", .{
    .target = target,
    .optimize = optimize,
});
exe.linkLibrary(sdl_net_dependency.artifact("sdl_net"));
```

This will add the SDL_net library and header to `exe`.
