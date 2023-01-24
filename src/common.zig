const std = @import("std");
const mem = std.mem;
const types = @import("types.zig");

pub const panicf = std.debug.panic;
pub fn ptrAlign(comptime Ptr: type) comptime_int {
    return @typeInfo(Ptr).Pointer.alignment;
}

pub fn ptrAlignCast(comptime Ptr: type, ptr: anytype) Ptr {
    return @ptrCast(Ptr, @alignCast(ptrAlign(Ptr), ptr));
}

pub fn ptrfmt(ptr: anytype) PtrFmt {
    return .{ .ptr = @ptrToInt(ptr) };
}

pub const PtrFmt = struct {
    ptr: usize,

    pub fn format(value: PtrFmt, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("@{x}", .{value.ptr});
    }
};

pub fn firstNBytes(s: []const u8, n: usize) []const u8 {
    return s[0..@min(s.len, n)];
}
pub fn afterLastIndexOf(s: []const u8, delimiter: u8) []const u8 {
    const start = if (mem.lastIndexOfScalar(u8, s, delimiter)) |i| i + 1 else 0;
    return s[start..];
}
fn WithSentinel(comptime T: type) type {
    return if (std.meta.sentinel(T)) |s|
        [:s]const std.meta.Child(T)
    else
        T;
}
pub fn splitOn(comptime T: type, s: T, delimiter: std.meta.Child(T)) [2]T {
    const start = if (mem.lastIndexOfScalar(std.meta.Child(T), s, delimiter)) |i| i else 0;
    return [2]T{ s[0..start], s[start + 1 ..] };
}
pub fn todo(comptime fmt: []const u8, args: anytype) noreturn {
    panicf("TODO " ++ fmt, args);
}
pub fn compileErr(comptime fmt: []const u8, args: anytype) noreturn {
    @compileError(std.fmt.comptimePrint(fmt, args));
}

pub fn repeatedEleSize(t: types.FieldDescriptorProto.Type) u8 {
    return switch (t) {
        .TYPE_SINT32,
        .TYPE_INT32,
        .TYPE_UINT32,
        .TYPE_SFIXED32,
        .TYPE_FIXED32,
        .TYPE_FLOAT,
        .TYPE_ENUM,
        => 4,
        .TYPE_SINT64,
        .TYPE_INT64,
        .TYPE_UINT64,
        .TYPE_SFIXED64,
        .TYPE_FIXED64,
        .TYPE_DOUBLE,
        => 8,
        .TYPE_BOOL => @sizeOf(bool),
        .TYPE_STRING => @sizeOf(types.String),
        .TYPE_MESSAGE => @sizeOf(*types.Message),
        .TYPE_BYTES => @sizeOf(types.BinaryData),
        .TYPE_ERROR, .TYPE_GROUP => unreachable,
    };
}

pub fn flagsContain(flags: anytype, flag: anytype) bool {
    const Set = std.enums.EnumSet(@TypeOf(flag));
    const I = @TypeOf(@as(Set, undefined).bits.mask);
    const bitset = Set{ .bits = .{ .mask = @truncate(I, flags) } };
    return bitset.contains(flag);
}
