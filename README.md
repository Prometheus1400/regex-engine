# regex-engine

A small Zig regex engine with compile-time pattern parsing.

Supported syntax: literal characters, `.`, grouping with `(...)`, `*`, and `+`.
Matches are full-string matches.

```zig
const regex = @import("regex_engine");

const compiled = try regex.compile("a(bc)+");
const ok = compiled.pattern().matches(allocator, "abcbc");
```

Run tests:

```sh
zig build test
```
