const std = @import("std");
const print = std.debug.print;
const mem = std.mem;
const assert = std.debug.assert;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;

const GlobalAlloc = std.heap.GeneralPurposeAllocator(.{});
var GlobalAllocator: GlobalAlloc = .{};

pub const Global = GlobalAllocator.allocator();
pub const Pages = std.heap.page_allocator;

const BumpState = struct {
    ranges: ArrayList([]u8),
    next_size: usize,

    const Self = @This();

    fn init(initial_size: usize, allocator: Allocator) Self {
        return .{
            .ranges = ArrayList([]u8).init(allocator),
            .next_size = initial_size,
        };
    }

    fn allocate(bump: *Self, mark: *Mark, len: usize, ptr_align: u29, len_align: u29, ret_addr: usize) Allocator.Error![]u8 {
        if (mark.range < bump.ranges.items.len) {
            const range = bump.ranges.items[mark.range];

            const addr = @ptrToInt(range.ptr) + mark.index_in_range;
            const adjusted_addr = mem.alignForward(addr, ptr_align);
            const adjusted_index = mark.index_in_range + (adjusted_addr - addr);
            const new_end_index = adjusted_index + len;

            if (new_end_index <= range.len) {
                mark.index_in_range = new_end_index;

                return range[adjusted_index..new_end_index];
            }
        }

        const size = @maximum(len, bump.next_size);

        const alloc = bump.ranges.allocator;
        const slice = try alloc.rawAlloc(size, ptr_align, len_align, ret_addr);
        try bump.ranges.append(slice);

        // grow the next arena, but keep it to at most 1GB please
        bump.next_size = size * 3 / 2;
        bump.next_size = @minimum(1024 * 1024 * 1024, bump.next_size);

        mark.range = bump.ranges.items.len - 1;
        mark.index_in_range = len;

        return slice[0..len];
    }
};

pub const Mark = struct {
    range: usize,
    index_in_range: usize,

    const ZERO: @This() = .{
        .range = 0,
        .index_in_range = 0,
    };
};

pub const Bump = struct {
    bump: BumpState,
    mark: Mark,

    const Self = @This();

    pub fn init(initial_size: usize, alloc: Allocator) Self {
        return .{
            .bump = BumpState.init(initial_size, alloc),
            .mark = Mark.ZERO,
        };
    }

    pub fn deinit(self: *Self) void {
        const alloc = self.bump.ranges.allocator;
        for (self.bump.ranges.items) |range| {
            alloc.free(range);
        }

        self.bump.ranges.deinit();
    }

    pub fn allocator(self: *Self) Allocator {
        const resize = Allocator.NoResize(Self).noResize;
        const free = Allocator.NoOpFree(Self).noOpFree;

        return Allocator.init(self, Self.allocate, resize, free);
    }

    fn allocate(self: *Self, len: usize, ptr_align: u29, len_align: u29, ret_addr: usize) Allocator.Error![]u8 {
        return self.bump.allocate(&self.mark, len, ptr_align, len_align, ret_addr);
    }
};

pub const Temp = struct {
    mark: Mark,
    previous: ?*Self,

    const Self = @This();

    const InitialSize = 1024 * 1024 * 4;

    threadlocal var top: ?*Temp = null;
    threadlocal var bump = BumpState.init(InitialSize, Global);

    pub fn init() Self {
        var mark = Mark.ZERO;

        if (top) |t| {
            mark = t.mark;
        }

        return .{
            .mark = mark,
            .previous = top,
        };
    }

    pub fn deinit(self: *Self) void {
        if (std.debug.runtime_safety) {
            if (top) |t| {
                assert(t == self or t == self.previous);
            }
        }

        top = self.previous;

        // can do some incremental sorting here too at some point
        //                             - Albert Liu, Mar 31, 2022 Thu 02:45 EDT

        // const temp = self.previous orelse self;
        // const unused = bump.ranges.items[(temp.mark.range + 1)..];

        // print("len: {} r: {}\n", .{ bump.ranges.items.len, temp.mark.range });
        // for (bump.ranges.items) |range| {
        //     print("len: {}\n", .{range.len});
        // }

        // std.sort.insertionSort([]u8, unused, {}, lessThan);
    }

    fn lessThan(_: void, left: []u8, right: []u8) bool {
        return left.len < right.len;
    }

    pub fn allocator(self: *Self) Allocator {
        if (std.debug.runtime_safety) {
            if (top) |t| {
                assert(t == self or t == self.previous);
            }
        }

        top = self;

        const resize = Allocator.NoResize(Self).noResize;
        const free = Allocator.NoOpFree(Self).noOpFree;

        return Allocator.init(self, Self.allocate, resize, free);
    }

    fn allocate(self: *Self, len: usize, ptr_align: u29, len_align: u29, ret_addr: usize) Allocator.Error![]u8 {
        // Bruh what, why is this necessary
        bump.ranges.allocator = Global;

        return bump.allocate(&self.mark, len, ptr_align, len_align, ret_addr);
    }
};
