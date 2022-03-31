const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

threadlocal var alloc: StackAlloc = .{
    ranges: ArrayList([]u8).init(),
};

const StackAlloc = struct {
    ranges: ArrayList([]u8),

    fn alloc(ptr: *StackAlloc, len: usize, ptr_align: u29, len_align: u29, ret_addr: usize) Error![]u8 {
    }

    fn resize(ptr: *StackAlloc, buf: []u8, buf_align: u29, new_len: usize, len_align: u29, ret_addr: usize) ?usize {
    }

    fn free(ptr: *StackAlloc, buf: []u8, buf_align: u29, ret_addr: usize) void {
    }

};

pub fn stack() Allocator {
    return Allocator.init(StackAlloc.free);
}
