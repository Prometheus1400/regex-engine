pub const Expr = union(enum) {
    wildcard,
    char: u8,
    concat: struct { usize, usize },
    starred: usize,
    plussed: usize,
};

pub fn ParserResult(comptime max_nodes: usize) type {
    return struct {
        root: usize,
        expr_arr: [max_nodes]Expr,
        expr_arr_size: usize,
    };
}
