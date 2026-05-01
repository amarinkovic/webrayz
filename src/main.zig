const std = @import("std");
const builtin = @import("builtin");
const rl = @import("raylib");

// Zig 0.16's default debug Io is std.Io.Threaded, which currently fails to
// compile for wasm32-emscripten. On emscripten route std.debug through a
// no-op Io and trap on panic; native keeps default behavior.
pub const std_options_debug_io: std.Io = if (builtin.os.tag == .emscripten)
    std.Io.failing
else
    std.Io.Threaded.global_single_threaded.io();
pub const panic = if (builtin.os.tag == .emscripten) std.debug.no_panic else std.debug.FullPanic(std.debug.defaultPanic);

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 450;

extern fn emscripten_set_main_loop_arg(func: *const fn (?*anyopaque) callconv(.c) void, arg: ?*anyopaque, fps: c_int, simulate_infinite_loop: c_int) void;

const Ball = struct {
    position: rl.Vector2,
    size: f32,
    speed: rl.Vector2,

    pub fn init(x: f32, y: f32, size: f32, speed: f32) Ball {
        return Ball{
            .position = rl.Vector2.init(x, y),
            .size = size,
            .speed = rl.Vector2.init(speed, speed),
        };
    }

    pub fn update(self: *Ball) void {
        self.position.x += self.speed.x;
        self.position.y += self.speed.y;

        if (self.position.y <= self.size or self.position.y + self.size >= SCREEN_HEIGHT) {
            self.speed.y *= -1;
        }

        if (self.position.x <= self.size or self.position.x + self.size >= SCREEN_WIDTH) {
            self.speed.x *= -1;
        }
    }

    pub fn draw(self: *const Ball) void {
        rl.drawCircleV(self.position, self.size, rl.Color.red);
    }
};

fn updateDrawFrame(arg: ?*anyopaque) callconv(.c) void {
    const ball = @as(*Ball, @ptrCast(@alignCast(arg.?)));

    ball.update();

    rl.beginDrawing();
    defer rl.endDrawing();

    rl.clearBackground(rl.Color.black);
    ball.draw();
    rl.drawText("All you codebase are belong to us!", 190, 200, 20, rl.Color.green);
}

pub fn main() void {
    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "webrayz");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var ball = Ball.init(20, 20, 20, 3);

    if (builtin.os.tag == .emscripten) {
        emscripten_set_main_loop_arg(updateDrawFrame, &ball, 0, 1);
    } else {
        while (!rl.windowShouldClose()) {
            updateDrawFrame(&ball);
        }
    }
}
