const std = @import("std");

pub const Pattern = struct {
    impl: *const anyopaque,
    v_matches: *const fn (*const anyopaque, std.mem.Allocator, []const u8) bool,

    const Self = @This();

    /// Returns true when this compiled pattern matches the entire input string.
    /// The allocator is used only for temporary scratch storage during matching.
    pub fn matches(self: *const Self, allocator: std.mem.Allocator, str: []const u8) bool {
        return self.v_matches(self.impl, allocator, str);
    }
};
