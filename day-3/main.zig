const std = @import("std");
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

test "sum part numbers" {
    const example: []const u8 =
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\......755.
        \\...$.*....
        \\.664.598..
    ;
    const sum = try sumPartNumbers(std.testing.allocator, example);
    try expect(sum == 4361);
}

const Symbol = struct {
    row: i32,
    col: i32,
    value: u8,
};

const PartNumber = struct {
    row: i32,
    col: i32,
    span: i32,
    value: i32,

    fn isClose(part: PartNumber, symbol: Symbol) bool {
        const row_match = symbol.row >= @max(part.row - 1, 0) and symbol.row <= part.row + 1;
        const col_match = symbol.col >= @max(part.col - 1, 0) and symbol.col <= part.col + part.span;
        return col_match and row_match;
    }
};

fn sumPartNumbers(allocator: Allocator, chars: []const u8) !i32 {
    var it = std.mem.splitAny(u8, chars, "\n");

    var part_numbers = try std.ArrayListUnmanaged(PartNumber).initCapacity(allocator, 2048);
    defer part_numbers.deinit(allocator);

    var symbols = try std.ArrayListUnmanaged(Symbol).initCapacity(allocator, 2048);
    defer symbols.deinit(allocator);

    var row: i32 = 0;
    var buf_idx: u8 = 0;
    var buf = [_]u8{0} ** 32;

    while (it.next()) |line| {
        defer row += 1;
        if (line.len == 0) {
            break;
        }

        var col: i32 = 0;
        for (line) |char| {
            defer col += 1;
            if (std.ascii.isDigit(char)) {
                buf[buf_idx] = char;
                buf_idx += 1;
            } else {
                if (buf_idx > 0) {
                    const value = try std.fmt.parseInt(i32, buf[0..buf_idx], 10);
                    const pn: PartNumber = .{ .row = row, .col = col - buf_idx, .span = buf_idx, .value = value };
                    try part_numbers.append(allocator, pn);
                    buf_idx = 0;
                }
                if (char != '.') {
                    const sy: Symbol = .{ .row = row, .col = col, .value = char };
                    try symbols.append(allocator, sy);
                }
            }
        }
    }

    var sum: i32 = 0;
    for (part_numbers.items) |part| {
        for (symbols.items) |symbol| {
            if (part.isClose(symbol)) {
                std.debug.print("{} is close to {c}\n", .{ part.value, symbol.value });
                sum += part.value;
            }
        }
    }
    return sum;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    const buffer = try std.io.getStdIn().readToEndAlloc(allocator, 5 * 1_000_000_000);
    const sum = try sumPartNumbers(allocator, buffer);
    std.debug.print("Parts: {}\n", .{sum});
}
