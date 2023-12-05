const std = @import("std");
const expect = std.testing.expect;

test "read game configurations" {
    const example: []const u8 =
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    ;

    try expect(try find_impossible(example) == 8);
}

const GameInfo = struct {
    id: i32,
    red: i32,
    green: i32,
    blue: i32,

    pub fn parse_revealed(self: GameInfo, chars: []const u8) !GameInfo {
        const it = std.mem.splitAny(u8, chars, " ");
        _ = it.next(); // Game
        self.id = try std.fmt.parseInt(i32, std.mem.trimRight(u8, it.next(), ":"), 10);

        var lastCount: i32 = 0;
        for (it, 0..) |token, i| {
            if (i % 2 == 0) {
                // even, this is a count
                lastCount = try std.fmt.parseInt(i32, token, 10);
            } else {
                // This is the color
                const color = std.mem.trimRight(u8, token, ",;");
                // switch (color) {
                //     "red" =>
                // }
            }
        }
    }
};

test "parse revealed" {
    const example: []const u8 = "Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green";
    const info = try GameInfo.parse_revealed(example);
    try expect(info.id == 1);
    try expect(info.red == 4);
    try expect(info.green == 2);
    try expect(info.blue == 6);
}

fn find_impossible(chars: []const u8) !i32 {
    return 1;
}

pub fn main() !void {}
