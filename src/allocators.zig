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

const TempStorageGlobal = struct {
    ranges: ArrayList([]u8),
    next_size: usize,
    current: usize,
    top_stack_reader: if (std.debug.runtime_safety) ?*Temp else void,
};

const TempStorageInitialSize = 1024 * 1024 * 4;
threadlocal var temporary_storage: TempStorageGlobal = .{
    .ranges = ArrayList([]u8).init(Pages),
    .next_size = TempStorageInitialSize,
    .current = 0,
    .top_stack_reader = if (std.debug.runtime_safety) null else {},
};

pub const Temp = struct {
    range: usize,
    index_in_range: usize,
    previous: if (std.debug.runtime_safety) ?*Self else void,

    const Self = @This();

    pub fn init() Self {
        return .{
            .range = 0,
            .index_in_range = 0,
            .previous = temporary_storage.top_stack_reader,
        };
    }

    pub fn deinit(self: *Self) void {
        if (std.debug.runtime_safety) {
            if (temporary_storage.top_stack_reader) |top| {
                assert(top == self or top == self.previous);
            }

            temporary_storage.top_stack_reader = self.previous;
        }

        // can do some incremental sorting here to at some point
        //                             - Albert Liu, Mar 31, 2022 Thu 02:45 EDT
    }

    pub fn allocator(self: *Self) Allocator {
        if (std.debug.runtime_safety) {
            if (temporary_storage.top_stack_reader) |top| {
                assert(top == self or top == self.previous);
            }

            temporary_storage.top_stack_reader = self;
        }

        return Allocator.init(self, Self.allocate, Self.resize, Self.free);
    }

    // the type passed isn't *really* a pointer, but meh
    fn allocate(self: *Self, len: usize, ptr_align: u29, len_align: u29, ret_addr: usize) Allocator.Error![]u8 {
        const tmp = &temporary_storage;

        // Bruh what, why is this necessary
        tmp.ranges.allocator = Pages;

        var new_len = len;
        if (len_align != 0) {
            new_len = mem.alignForward(len, len_align);
        }

        if (self.range < tmp.ranges.items.len) {
            const range = tmp.ranges.items[self.range];

            const addr = @ptrToInt(range.ptr) + self.index_in_range;
            const adjusted_addr = mem.alignForward(addr, ptr_align);
            const adjusted_index = self.index_in_range + (adjusted_addr - addr);
            const new_end_index = adjusted_index + new_len;

            if (new_end_index <= range.len) {
                self.index_in_range = new_end_index;

                return range[adjusted_index..new_end_index];
            }
        }

        const size = @maximum(len, tmp.next_size);

        const slice = try Pages.rawAlloc(size, ptr_align, len_align, ret_addr);
        try tmp.ranges.append(slice);

        // grow the next arena, but keep it to at most 1GB please
        tmp.next_size = size * 3 / 2;
        tmp.next_size = @minimum(1024 * 1024 * 1024, tmp.next_size);

        self.range = tmp.ranges.items.len - 1;
        self.index_in_range = size;

        return slice[0..size];
    }

    fn resize(_: *Self, _: []u8, _: u29, len: usize, len_align: u29, _: usize) ?usize {
        var new_len = len;
        if (len_align != 0) {
            new_len = mem.alignForward(len, len_align);
        }

        if (new_len <= len) {
            return new_len;
        }

        return null;
    }

    fn free(_: *Self, _: []u8, _: u29, _: usize) void {}
};
