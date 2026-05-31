const std = @import("std");

const ast = @import("ast.zig");
const pattern_mod = @import("pattern.zig");

/// Returns an implementation of Pattern that walks or "interprets" the AST directly.
pub fn PatternInterpreter(comptime max_nodes: usize) type {
    return struct {
        root: usize,
        node_buf: [max_nodes]ast.Expr,
        num_nodes: usize,

        const Self = @This();

        pub fn init(root: usize, node_buf: [max_nodes]ast.Expr, num_nodes: usize) Self {
            return .{
                .root = root,
                .node_buf = node_buf,
                .num_nodes = num_nodes,
            };
        }

        fn nodes(self: *const Self) []const ast.Expr {
            return self.node_buf[0..self.num_nodes];
        }

        /// Returns the possible end positions.
        fn matches(self: *const Self, allocator: std.mem.Allocator, str: []const u8, node: usize, i: usize) !std.ArrayListAlignedUnmanaged(usize, null) {
            const expr = self.nodes()[node];
            var list = std.ArrayListAlignedUnmanaged(usize, null).empty;
            switch (expr) {
                .char => |c| {
                    if (i < str.len and c == str[i]) {
                        try list.append(allocator, i + 1);
                    }
                    return list;
                },
                .wildcard => {
                    if (i < str.len) {
                        try list.append(allocator, i + 1);
                    }
                    return list;
                },
                .concat => |pair| {
                    const left_positions = try self.matches(allocator, str, pair.@"0", i);
                    for (left_positions.items) |mid| {
                        const right_positions = try self.matches(allocator, str, pair.@"1", mid);
                        try list.appendSlice(allocator, right_positions.items);
                    }
                    return list;
                },
                .plussed => |child| {
                    const child_positions = try self.matches(allocator, str, child, i);
                    for (child_positions.items) |mid| {
                        try list.append(allocator, mid);
                        if (mid == i) {
                            continue;
                        }
                        const more_positions = try self.matches(allocator, str, node, mid);
                        try list.appendSlice(allocator, more_positions.items);
                    }
                    return list;
                },
                .starred => |child| {
                    try list.append(allocator, i);

                    const child_positions = try self.matches(allocator, str, child, i);
                    for (child_positions.items) |mid| {
                        if (mid == i) {
                            continue;
                        }

                        const more_positions = try self.matches(allocator, str, node, mid);
                        try list.appendSlice(allocator, more_positions.items);
                    }
                    return list;
                },
            }
        }

        fn matches_impl(impl: *const anyopaque, allocator: std.mem.Allocator, str: []const u8) bool {
            const self: *const Self = @ptrCast(@alignCast(impl));
            var arena_allocator = std.heap.ArenaAllocator.init(allocator);
            defer arena_allocator.deinit();

            const possible_end_positions = self.matches(arena_allocator.allocator(), str, self.root, 0) catch return false;
            for (possible_end_positions.items) |pos| {
                if (pos == str.len) {
                    return true;
                }
            }
            return false;
        }

        pub fn pattern(self: *const Self) pattern_mod.Pattern {
            return .{
                .impl = self,
                .v_matches = matches_impl,
            };
        }
    };
}
