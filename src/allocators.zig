const std = @import("std");
const mem = std.mem;

const assert = std.debug.assert;

const Allocator = mem.Allocator;
// const ArrayList = std.ArrayList;
const ByteList = std.ArrayListAlignedUnmanaged([]u8, null);
const GlobalAlloc = std.heap.GeneralPurposeAllocator(.{});

var GlobalAllocator: GlobalAlloc = .{};
pub const Alloc = GlobalAllocator.allocator();
pub const Pages = std.heap.page_allocator;

const BumpState = struct {
    const Self = @This();

    ranges: ByteList,
    next_size: usize,

    fn init(initial_size: usize) Self {
        return .{
            .ranges = ByteList{},
            .next_size = initial_size,
        };
    }

    fn allocate(bump: *Self, mark: *Mark, alloc: Allocator, len: usize, ptr_align: u29, len_align: u29, ret_addr: usize) Allocator.Error![]u8 {
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

        const slice = try alloc.rawAlloc(size, ptr_align, len_align, ret_addr);
        try bump.ranges.append(alloc, slice);

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
    const Self = @This();

    bump: BumpState,
    mark: Mark,
    alloc: Allocator,

    pub fn init(initial_size: usize, alloc: Allocator) Self {
        return .{
            .bump = BumpState.init(initial_size),
            .mark = Mark.ZERO,
            .alloc = alloc,
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.bump.ranges.items) |range| {
            self.alloc.free(range);
        }

        self.bump.ranges.deinit(self.alloc);
    }

    pub fn allocator(self: *Self) Allocator {
        const resize = Allocator.NoResize(Self).noResize;
        const free = Allocator.NoOpFree(Self).noOpFree;

        return Allocator.init(self, Self.allocate, resize, free);
    }

    fn allocate(self: *Self, len: usize, ptr_align: u29, len_align: u29, ret_addr: usize) Allocator.Error![]u8 {
        return self.bump.allocate(&self.mark, self.alloc, len, ptr_align, len_align, ret_addr);
    }
};

pub const Temp = struct {
    const Self = @This();

    mark: Mark,
    previous: ?*Self,

    const InitialSize = 1024 * 1024;

    threadlocal var top: ?*Temp = null;
    threadlocal var bump = BumpState.init(InitialSize);

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
        return bump.allocate(&self.mark, Alloc, len, ptr_align, len_align, ret_addr);
    }
};

pub const Frame = FrameAlloc.allocator;

pub fn clearFrameAllocator() void {
    FrameAlloc.mark = Mark.ZERO;
}

const FrameAlloc = struct {
    const InitialSize = 4 * 1024 * 1024;
    threadlocal var bump = BumpState.init(InitialSize);
    threadlocal var mark = Mark.ZERO;

    const allocator = Allocator.init(&GlobalAllocator, alloc, resize, free);

    const resize = Allocator.NoResize(GlobalAlloc).noResize;
    const free = Allocator.NoOpFree(GlobalAlloc).noOpFree;

    fn alloc(_: *GlobalAlloc, len: usize, ptr_align: u29, len_align: u29, ret_addr: usize) Allocator.Error![]u8 {
        return bump.allocate(&mark, Alloc, len, ptr_align, len_align, ret_addr);
    }
};
