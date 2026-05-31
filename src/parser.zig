const std = @import("std");

const ast = @import("ast.zig");
const tokenizer = @import("tokenizer.zig");

pub fn Parser(comptime str: []const u8) type {
    const stack_size = 20;
    const max_nodes = str.len * 4;

    return struct {
        tokenizer: tokenizer.Tokenizer,
        expr_arr: [max_nodes]ast.Expr,
        i: usize,
        cur_stack: [stack_size]?usize,
        cur_stack_depth: usize,

        const Self = @This();
        pub const init = Self{
            .tokenizer = tokenizer.Tokenizer.init(str),
            .expr_arr = undefined,
            .i = 0,
            .cur_stack = .{null} ** stack_size,
            .cur_stack_depth = 0,
        };

        fn add(self: *Self, node: ast.Expr) void {
            self.expr_arr[self.i] = node;
            self.i += 1;
        }

        fn get_cur(self: *const Self) ?usize {
            return self.cur_stack[self.cur_stack_depth];
        }

        fn set_cur(self: *Self, n: usize) void {
            self.cur_stack[self.cur_stack_depth] = n;
        }

        fn enter_group(self: *Self) !void {
            if (self.cur_stack_depth + 1 >= self.cur_stack.len) {
                return error.StackOverflow;
            }
            self.cur_stack_depth += 1;
        }

        fn exit_group(self: *Self) !void {
            if (self.cur_stack_depth == 0) {
                return error.StackUnderflow;
            }
            self.cur_stack[self.cur_stack_depth] = null;
            self.cur_stack_depth -= 1;
        }

        pub fn parse(self: *Self) !ast.ParserResult(max_nodes) {
            while (try self.tokenizer.peek() != .eof) {
                const token = try self.tokenizer.next();
                switch (token) {
                    .l_paren => {
                        try self.enter_group();
                    },
                    .r_paren => {
                        const res = self.get_cur() orelse return error.EmptyParenthesis;
                        try self.exit_group();
                        switch (try self.tokenizer.peek()) {
                            .star => {
                                self.add(.{ .starred = res });
                                _ = try self.tokenizer.next();
                                if (self.get_cur()) |cur| {
                                    self.add(.{ .concat = .{ cur, self.i - 1 } });
                                }
                            },
                            .plus => {
                                self.add(.{ .plussed = res });
                                _ = try self.tokenizer.next();
                                if (self.get_cur()) |cur| {
                                    self.add(.{ .concat = .{ cur, self.i - 1 } });
                                }
                            },
                            else => {
                                if (self.get_cur()) |cur| {
                                    self.add(.{ .concat = .{ cur, res } });
                                }
                            },
                        }
                        self.set_cur(self.i - 1);
                    },
                    .char => |c| {
                        self.add(.{ .char = c });
                        switch (try self.tokenizer.peek()) {
                            .star => {
                                self.add(.{ .starred = self.i - 1 });
                                _ = try self.tokenizer.next();
                            },
                            .plus => {
                                self.add(.{ .plussed = self.i - 1 });
                                _ = try self.tokenizer.next();
                            },
                            else => {},
                        }
                        if (self.get_cur()) |cur| {
                            self.add(.{ .concat = .{ cur, self.i - 1 } });
                        }
                        self.set_cur(self.i - 1);
                    },
                    .wildcard => {
                        self.add(.wildcard);
                        switch (try self.tokenizer.peek()) {
                            .star => {
                                self.add(.{ .starred = self.i - 1 });
                                _ = try self.tokenizer.next();
                            },
                            .plus => {
                                self.add(.{ .plussed = self.i - 1 });
                                _ = try self.tokenizer.next();
                            },
                            else => {},
                        }
                        if (self.get_cur()) |cur| {
                            self.add(.{ .concat = .{ cur, self.i - 1 } });
                        }
                        self.set_cur(self.i - 1);
                    },
                    .plus => {},
                    .star => {},
                    .eof => {},
                }
            }

            if (self.cur_stack_depth != 0) {
                return error.MismatchedParenthesis;
            }

            return ast.ParserResult(max_nodes){
                .root = self.get_cur().?,
                .expr_arr = self.expr_arr,
                .expr_arr_size = self.i,
            };
        }
    };
}

test "simple parser" {
    var parser = Parser("abc").init;
    const res = try parser.parse();

    try std.testing.expectEqual(res.expr_arr[res.root], ast.Expr{ .concat = .{ 2, 3 } });
}

test "simple parser with star" {
    var parser = Parser("abc*").init;
    const res = try parser.parse();

    try std.testing.expectEqual(res.expr_arr[res.root], ast.Expr{ .concat = .{ 2, 4 } });
}

test "simple parser with group and star" {
    var parser = Parser("a(bc)*").init;
    const res = try parser.parse();

    try std.testing.expectEqual(res.expr_arr[res.root], ast.Expr{ .concat = .{ 0, 4 } });
}
