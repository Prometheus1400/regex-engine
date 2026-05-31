pub const Token = union(enum) {
    l_paren,
    r_paren,
    plus,
    star,
    char: u8,
    wildcard,
    eof,
};

pub const Error = error{
    InvalidCharacter,
};

pub const Tokenizer = struct {
    i: usize = 0,
    str: []const u8,
    cache: ?Token = null,

    const Self = @This();

    pub fn init(comptime str: []const u8) Self {
        return .{ .str = str };
    }

    fn peek_char(self: *const Self) ?u8 {
        if (self.i >= self.str.len) {
            return null;
        }
        return self.str[self.i];
    }

    pub fn peek(self: *Self) !Token {
        if (self.cache) |tok| {
            return tok;
        }
        self.cache = try self.next();
        return self.cache.?;
    }

    pub fn next(self: *Self) !Token {
        if (self.cache) |tok| {
            self.cache = null;
            return tok;
        }
        const token: Token = switch (self.peek_char() orelse return .eof) {
            '(' => .l_paren,
            ')' => .r_paren,
            '+' => .plus,
            '*' => .star,
            '.' => .wildcard,
            '0'...'9', 'a'...'z', 'A'...'Z' => |c| .{ .char = c },
            else => {
                return error.InvalidCharacter;
            },
        };
        self.i += 1;
        return token;
    }
};
