const std = @import("std");
const time = std.time;

const Timer = time.Timer;
const Instant = time.Instant;

const cast = std.math.cast;

pub const SimTimer = struct {
    const Self = @This();

    const TrialCount: usize = 32;
    const TargetDelta: u64 = @floatToInt(u64, 1000.0 / 60.0 * 1000.0 * 1000.0);

    timer: Timer,
    begin: usize,
    trials: [TrialCount]f32,

    pub fn init() Self {
        const timer = Timer.start() catch @panic("wtf?");

        var trials = [_]f32{0} ** TrialCount;
        trials[0] = TargetDelta;

        return .{
            .timer = timer,
            .begin = 1,
            .trials = trials,
        };
    }

    pub fn frameTimeMs(self: *Self) f32 {
        const nano_compute = self.timer.lap();
        var nano_frame = nano_compute;

        // These multiplications mean that if we have around a 10% margin, we
        // should just run another frame immediately, instead of trying to
        // sleep.
        if (10 * nano_compute < 9 * TargetDelta) {
            time.sleep(TargetDelta - nano_frame);

            nano_frame += self.timer.lap();
        }

        const ms_compute = @intToFloat(f32, nano_compute) / 1_000_000;
        const ms_frame = @intToFloat(f32, nano_frame) / 1_000_000;

        const index = self.begin % self.trials.len;
        self.begin = index + 1;

        self.trials[index] = ms_compute;

        return ms_frame;
    }

    pub fn prevFrameComputeMs(self: *Self) f32 {
        const index = (self.begin - 1) % self.trials.len;

        return self.trials[index];
    }
};

// Zig does quite a bit of typechecking-level laziness, and sometimes we want to
// force it to compile all branches, even if one of them statically will never
// run.
pub fn runtime_true() bool {
    return true;
}
