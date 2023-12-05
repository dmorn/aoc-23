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
const Lookup = [_]PatternMatch{
    .{ .pattern = "z", .match = .partial },
    .{ .pattern = "ze", .match = .partial },
    .{ .pattern = "zer", .match = .partial },
    .{ .pattern = "zero", .match = .zero },
    .{ .pattern = "o", .match = .partial },
    .{ .pattern = "on", .match = .partial },
    .{ .pattern = "one", .match = .one },
    .{ .pattern = "t", .match = .partial },
    .{ .pattern = "tw", .match = .partial },
    .{ .pattern = "two", .match = .two },
    .{ .pattern = "th", .match = .partial },
    .{ .pattern = "thr", .match = .partial },
    .{ .pattern = "thre", .match = .partial },
    .{ .pattern = "three", .match = .three },
    .{ .pattern = "f", .match = .partial },
    .{ .pattern = "fo", .match = .partial },
    .{ .pattern = "fou", .match = .partial },
    .{ .pattern = "four", .match = .four },
    .{ .pattern = "fi", .match = .partial },
    .{ .pattern = "fiv", .match = .partial },
    .{ .pattern = "five", .match = .five },
    .{ .pattern = "s", .match = .partial },
    .{ .pattern = "si", .match = .partial },
    .{ .pattern = "six", .match = .six },
    .{ .pattern = "se", .match = .partial },
    .{ .pattern = "sev", .match = .partial },
    .{ .pattern = "seve", .match = .partial },
    .{ .pattern = "seven", .match = .seven },
    .{ .pattern = "e", .match = .partial },
    .{ .pattern = "ei", .match = .partial },
    .{ .pattern = "eig", .match = .partial },
    .{ .pattern = "eigh", .match = .partial },
    .{ .pattern = "eight", .match = .eight },
    .{ .pattern = "n", .match = .partial },
    .{ .pattern = "ni", .match = .partial },
    .{ .pattern = "nin", .match = .partial },
    .{ .pattern = "nine", .match = .nine },
};

fn match(chars: []const u8) Match {
    for (Lookup) |item| {
        if (std.mem.eql(u8, item.pattern, chars)) {
            return item.match;
        }
    }
    return .none;
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
