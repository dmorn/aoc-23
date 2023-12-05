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

const Match = enum { partial, full, none };

const SpelledDigit = struct {
    pattern: []const u8,
    value: u8,

    pub fn match(self: SpelledDigit, pattern: []u8) Match {
        if (pattern.len > self.pattern.len) {
            return .none;
        }
        const submatch: []const u8 = self.pattern[0..pattern.len];
        if (std.mem.eql(u8, submatch, pattern)) {
            if (self.pattern.len == pattern.len) {
                return .full;
            }
            return .partial;
        }
        return .none;
    }
};

const lookup = [_]SpelledDigit{
    SpelledDigit{ .pattern = "zero", .value = 48 },
    SpelledDigit{ .pattern = "one", .value = 49 },
    SpelledDigit{ .pattern = "two", .value = 50 },
    SpelledDigit{ .pattern = "three", .value = 51 },
    SpelledDigit{ .pattern = "four", .value = 52 },
    SpelledDigit{ .pattern = "five", .value = 53 },
    SpelledDigit{ .pattern = "six", .value = 54 },
    SpelledDigit{ .pattern = "seven", .value = 55 },
    SpelledDigit{ .pattern = "eight", .value = 56 },
    SpelledDigit{ .pattern = "nine", .value = 57 },
};

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
            const part: []u8 = chars[from .. i + 1];
            var has_matched: bool = false;

            loop: for (lookup) |item| {
                switch (item.match(part)) {
                    .partial => has_matched = true,
                    .full => {
                        digits[idx] = item.value;
                        idx += 1;
                        // Include the last char of the match, they
                        // might be overlapping
                        from = @intCast(i);
                        has_matched = true;
                        break :loop;
                    },
                    .none => {},
                }
            }
            if (!has_matched) {
                from += 1;
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
