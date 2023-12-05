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

    try expect(try findPossible(example, 12, 13, 14) == 8);
}

const Game = struct {
    id: i32 = 0,
    red: i32 = 0,
    green: i32 = 0,
    blue: i32 = 0,

    pub fn fromLine(chars: []const u8) !Game {
        var it = std.mem.splitAny(u8, chars, " ");
        _ = it.next().?; // Game
        const id = try std.fmt.parseInt(i32, std.mem.trimRight(u8, it.next().?, ":"), 10);

        var r: i32 = 0;
        var g: i32 = 0;
        var b: i32 = 0;

        var last: i32 = 0;
        var i: i32 = 0;
        while (it.next()) |token| {
            defer i += 1;
            if (@rem(i, 2) == 0) {
                // even, this is a count
                last = try std.fmt.parseInt(i32, token, 10);
            } else {
                // This is the color
                const color = std.mem.trimRight(u8, token, ",;");
                if (std.mem.eql(u8, color, "red")) {
                    r = @max(last, r);
                } else if (std.mem.eql(u8, color, "green")) {
                    g = @max(last, g);
                } else if (std.mem.eql(u8, color, "blue")) {
                    b = @max(last, b);
                }
            }
        }

        return .{ .id = id, .red = r, .green = g, .blue = b };
    }

    pub fn isPossible(self: Game, red: i32, green: i32, blue: i32) bool {
        return self.red <= red and self.green <= green and self.blue <= blue;
    }
};

test "parse game" {
    const example: []const u8 = "Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green";
    const game = try Game.fromLine(example);
    try expect(game.id == 1);
    try expect(game.red == 4);
    try expect(game.green == 2);
    try expect(game.blue == 6);
}

fn findPossible(chars: []const u8, red: i32, green: i32, blue: i32) !i32 {
    var it = std.mem.splitAny(u8, chars, "\n");
    var ret: i32 = 0;

    while (it.next()) |line| {
        if (line.len == 0) {
            break;
        }
        const game = try Game.fromLine(line);
        if (game.isPossible(red, green, blue)) {
            ret += game.id;
        }
    }
    return ret;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    const buffer = try std.io.getStdIn().readToEndAlloc(allocator, 5 * 1_000_000_000);
    const possible = try findPossible(buffer, 12, 13, 14);
    std.debug.print("Possible Games: {}\n", .{possible});
}
