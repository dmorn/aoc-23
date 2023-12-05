const std = @import("std");
const expect = std.testing.expect;

test "read_calibration" {
    const example: []const u8 =
        \\two1nine
        \\eightwothree
        \\abcone2threexyz
        \\xtwone3four
        \\4nineeightseven2
        \\zoneight234
        \\7pqrstsixteen
        \\
    ;
    try expect(try read_calibration(example) == 281);
}

const Match = enum(u8) {
    none,
    partial,
    zero = 48,
    one = 49,
    two = 50,
    three = 51,
    four = 52,
    five = 53,
    six = 54,
    seven = 55,
    eight = 56,
    nine = 57,
};

const PatternMatch = struct {
    pattern: []const u8,
    match: Match,
};

// TODO: std.ComtimeStringMap!
// NOTE: benchmarks show that the previous approach with substring
// matching leads to similar results.
const lookup = std.ComptimeStringMap(Match, .{
    .{ "z", .partial },
    .{ "ze", .partial },
    .{ "zer", .partial },
    .{ "zero", .zero },
    .{ "o", .partial },
    .{ "on", .partial },
    .{ "one", .one },
    .{ "t", .partial },
    .{ "tw", .partial },
    .{ "two", .two },
    .{ "th", .partial },
    .{ "thr", .partial },
    .{ "thre", .partial },
    .{ "three", .three },
    .{ "f", .partial },
    .{ "fo", .partial },
    .{ "fou", .partial },
    .{ "four", .four },
    .{ "fi", .partial },
    .{ "fiv", .partial },
    .{ "five", .five },
    .{ "s", .partial },
    .{ "si", .partial },
    .{ "six", .six },
    .{ "se", .partial },
    .{ "sev", .partial },
    .{ "seve", .partial },
    .{ "seven", .seven },
    .{ "e", .partial },
    .{ "ei", .partial },
    .{ "eig", .partial },
    .{ "eigh", .partial },
    .{ "eight", .eight },
    .{ "n", .partial },
    .{ "ni", .partial },
    .{ "nin", .partial },
    .{ "nine", .nine },
});

fn match(chars: []const u8) Match {
    return lookup.get(chars) orelse .none;
}

fn read_calibration_line(chars: []u8) !i32 {
    var from: u8 = 0;
    var idx: u8 = 0;
    var digits = [_]u8{0} ** 256;

    for (chars, 0..) |char, i| {
        if (std.ascii.isDigit(char)) {
            digits[idx] = char;
            idx += 1;
            from = @intCast(i + 1);
        } else {
            const m = match(chars[from .. i + 1]);
            switch (m) {
                .none => from += 1,
                .partial => {},
                else => {
                    digits[idx] = @intFromEnum(m);
                    idx += 1;
                    // Include the last char of the match, they
                    // might be overlapping
                    from = @intCast(i);
                },
            }
        }
    }

    if (idx > 0) {
        const calibration: i32 = try std.fmt.parseInt(i32, &[2]u8{ digits[0], digits[@max(idx - 1, 0)] }, 10);
        return calibration;
    } else {
        return 0;
    }
}

fn read_calibration(chars: []const u8) !i32 {
    var calibration: i32 = 0;
    var line = [_]u8{0} ** 256;
    var size: u8 = 0;

    for (chars) |x| {
        switch (x) {
            10 => {
                calibration += try read_calibration_line(line[0..size]);
                size = 0;
            },
            else => {
                line[size] = x;
                size += 1;
            },
        }
    }
    return calibration;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    const buffer = try std.io.getStdIn().readToEndAlloc(allocator, 5 * 1_000_000_000);
    const calibration = try read_calibration(buffer);
    std.debug.print("Calibration: {}\n", .{calibration});
}
