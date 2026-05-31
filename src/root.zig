const std = @import("std");
const Io = std.Io;

pub const ast = @import("ast.zig");
pub const interpreter = @import("interpreter.zig");
pub const parser = @import("parser.zig");
pub const tokenizer = @import("tokenizer.zig");

pub const Pattern = @import("pattern.zig").Pattern;

pub fn compile(comptime str: []const u8) !interpreter.PatternInterpreter(str.len * 4) {
    var p = parser.Parser(str).init;
    const res = try p.parse();
    return interpreter.PatternInterpreter(res.expr_arr.len).init(res.root, res.expr_arr, res.expr_arr_size);
}

pub fn printAnotherMessage(writer: *Io.Writer) Io.Writer.Error!void {
    try writer.print("Run `zig build test` to run the tests.\n", .{});
}

test "compile and match work" {
    try expectMatch("a", "a", true);
    try expectMatch("a", "", false);
    try expectMatch("a", "b", false);
    try expectMatch("a", "aa", false);

    try expectMatch("abc", "abc", true);
    try expectMatch("abc", "ab", false);
    try expectMatch("abc", "abcd", false);
    try expectMatch("abc", "zabc", false);

    try expectMatch(".", "x", true);
    try expectMatch(".", "", false);
    try expectMatch("a.c", "abc", true);
    try expectMatch("a.c", "ac", false);

    try expectMatch("a*", "", true);
    try expectMatch("a*", "a", true);
    try expectMatch("a*", "aaa", true);
    try expectMatch("a*", "b", false);
    try expectMatch("ab*", "a", true);
    try expectMatch("ab*", "abbb", true);
    try expectMatch("ab*", "abbc", false);

    try expectMatch("a+", "", false);
    try expectMatch("a+", "a", true);
    try expectMatch("a+", "aaa", true);
    try expectMatch("a+", "b", false);

    try expectMatch("abc*", "ab", true);
    try expectMatch("abc*", "abc", true);
    try expectMatch("abc*", "abccc", true);
    try expectMatch("abc*", "accc", false);

    try expectMatch("a(bc)*", "a", true);
    try expectMatch("a(bc)*", "abc", true);
    try expectMatch("a(bc)*", "abcbc", true);
    try expectMatch("a(bc)*", "abcb", false);

    try expectMatch("a*a", "a", true);
    try expectMatch("a*a", "aaa", true);
    try expectMatch("a*a", "", false);

    try expectMatch("(ab)+ab(ab)*", "abab", true);
    try expectMatch("(ab)+ab(ab)*", "ababa", false);
    try expectMatch("(ab)+ab(ab)*", "ababab", true);
    try expectMatch("(ab)+ab(ab)*", "ab", false);

    try expectMatch("a(bc)+d", "abcd", true);
    try expectMatch("a(bc)+d", "abcbcd", true);
    try expectMatch("a(bc)+d", "ad", false);
    try expectMatch("a(bc)+d", "abcbc", false);

    try expectMatch("(a*)a", "a", true);
    try expectMatch("(a*)a", "aaaa", true);
    try expectMatch("(a*)a", "", false);

    try expectMatch("a.*c", "abc", true);
    try expectMatch("a.*c", "axyzc", true);
    try expectMatch("a.*c", "ac", true);
    try expectMatch("a.*c", "ab", false);

    try expectMatch("(ab)*(cd)+", "cd", true);
    try expectMatch("(ab)*(cd)+", "ababcdcd", true);
    try expectMatch("(ab)*(cd)+", "abab", false);
    try expectMatch("(ab)*(cd)+", "abcdc", false);

    try expectMatch("((ab)*)+c", "c", true);
    try expectMatch("((ab)*)+c", "abc", true);
    try expectMatch("((ab)*)+c", "abababc", true);
    try expectMatch("((ab)*)+c", "ababa", false);
}

fn expectMatch(comptime pattern_str: []const u8, input: []const u8, expected: bool) !void {
    const compiled = try compile(pattern_str);
    try std.testing.expectEqual(expected, compiled.pattern().matches(std.testing.allocator, input));
}
