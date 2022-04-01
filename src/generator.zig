const std = @import("std");
const expect = std.testing.expect;
const time = std.time;
const Timer = time.Timer;

// Helper class for Generator. An instance of this class is passed by pointer
// to functions which intend to be used in Generator instances. It is used to
// yield results.
//
// TODO: Find a better name for this. Thoughts: GeneratorProducer,
// GeneratorHandle.
fn Yielder(comptime T: type) type {
    return struct {
        const Self = @This();

        next_result: T = undefined,
        // Place to stash the frame where the generator
        frame: anyframe = undefined,

        pub fn yield(self: *Self, t: T) void {
            self.next_result = t;
            suspend {
                self.frame = @frame();
            }
        }
    };
}

// Class used to create an async generator from a function (generator_fn).
fn Generator(comptime T: type, comptime generator_fn: fn (*Yielder(T)) void) type {
    return struct {
        const Self = @This();

        // The object passed to generator_fn, which is used to yield results.
        yielder: Yielder(T) = Yielder(T){},
        // The original Frame returned by the async call to generator_fn.
        frame: @Frame(generator_fn) = undefined,
        // Whether next has been called yet.
        have_started: bool = false,

        // Calls (or resumes) the generator_fn to get the next result, and then
        // returns it once the generator_fn calls Yielder.yield(result).
        pub fn next(self: *Self) ?T {
            if (!self.have_started) {
                self.have_started = true;
                self.frame = async generator_fn(&self.yielder);
            } else {
                resume self.yielder.frame;
            }
            return self.yielder.next_result;
        }
    };
}

fn integers(generator: *Yielder(i64)) void {
    var n: i64 = 1;
    while (true) {
        generator.yield(n);
        n += 1;
    }
}

test "generate integers" {
    var generator = Generator(i64, integers){};
    var i: i64 = 1;
    while (i < 100000000) : (i += 1) {
        expect(generator.next() == i);
    }
}

fn squares(generator: *Yielder(i64)) void {
    var n: i64 = 1;
    while (true) {
        generator.yield(n * n);
        n += 1;
    }
}

test "generate squares" {
    var generator = Generator(i64, squares){};
    var i: i64 = 1;
    while (i < 100000) : (i += 1) {
        expect(generator.next() == i * i);
    }
}

fn fibonacci(generator: *Yielder(i64)) void {
    var a: i64 = 0;
    var b: i64 = 1;
    while (true) {
        const next = a + b;
        generator.yield(b);
        a = b;
        b = next;
    }
}

test "generate fibonacci" {
    var generator = Generator(i64, fibonacci){};

    expect(generator.next() == @intCast(i64, 1));
    expect(generator.next() == @intCast(i64, 1));
    expect(generator.next() == @intCast(i64, 2));
    expect(generator.next() == @intCast(i64, 3));
    expect(generator.next() == @intCast(i64, 5));
    expect(generator.next() == @intCast(i64, 8));
    expect(generator.next() == @intCast(i64, 13));
}

fn sum_integers_generator(n: i64) i64 {
    var generator = Generator(i64, integers){};
    var sum: i64 = 0;
    while (generator.next()) |i| {
        if (i >= n) break;

        sum += i;
    }
    return sum;
}

fn sum_integers(n: i64) i64 {
    var sum: i64 = 0;
    var i: i64 = 0;
    while (i < n) : (i += 1) {
        sum += i;
    }
    return sum;
}

// Silly benchmark to test normal iteration vs. generator. It's not really fair
// because there's a few other things going on in the generator case, like
// unpacking an optional, that's not going on in the "normal" case. Oh well.
// The "normal" version happens instantly though, while the generator case
// takes a few seconds on my MacBook pro (in ReleaseFast mode).
pub fn main() !void {
    const num_iterations = 100000000;
    {
        var timer = try Timer.start();
        const start = timer.lap();
        const sum = sum_integers(num_iterations);
        const end = timer.read();
        const elapsed_ms = @intToFloat(f64, end - start) / time.ns_per_ms;
        std.debug.print("sum: {}\n", .{sum});
        std.debug.print("time: {}\n", .{elapsed_ms});
    }

    {
        var timer = try Timer.start();
        const start = timer.lap();
        const sum = sum_integers_generator(num_iterations);
        const end = timer.read();
        const elapsed_ms = @intToFloat(f64, end - start) / time.ns_per_ms;
        std.debug.print("sum: {}\n", .{sum});
        std.debug.print("time: {}\n", .{elapsed_ms});
    }
}
