const std = @import("std");
const time = std.time;

const Timer = time.Timer;
const Instant = time.Instant;

const cast = std.math.cast;

pub const SimulationTimer = struct {
    const Self = @This();

    const TrialCount: usize = 32;
    const TargetDelta: u64 = @floatToInt(u64, 1000.0 / 60.0 * 1000.0 * 1000.0);

    timer: Timer,
    begin: usize,
    trials: [TrialCount]u32,

    pub fn init() Self {
        const timer = Timer.start() catch @panic("wtf?");

        var trials = [_]u32{0} ** TrialCount;
        trials[0] = TargetDelta;

        return .{
            .timer = timer,
            .begin = 1,
            .trials = trials,
        };
    }

    pub fn frameTimeDelta(self: *Self) u32 {
        const nano_elapsed = self.timer.lap();

        const ms_elapsed = cast(u32, nano_elapsed / 1000000) catch @panic("frame took too long");

        // These multiplications mean that if we're scraping by with around a 10%
        // margin, we should just shunt out another frame, instead of trying to
        // sleep.
        if (10 * nano_elapsed < 9 * TargetDelta) {
            time.sleep(TargetDelta - nano_elapsed);
            self.timer.reset();
        }

        const index = self.begin % self.trials.len;
        self.begin = index + 1;

        self.trials[index] = ms_elapsed;

        return ms_elapsed;
    }
};
