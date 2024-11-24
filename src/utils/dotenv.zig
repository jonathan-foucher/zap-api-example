const std = @import("std");

const testing = std.testing;
const Allocator = std.mem.Allocator;
const Self = @This();

map: std.process.EnvMap = undefined,

pub fn init(allocator: Allocator) !Self {
    var map = try std.process.getEnvMap(allocator);

    var file = std.fs.cwd().openFile(".env", .{}) catch {
        return .{ .map = map };
    };

    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len > 0 and line[0] == '#') {
            continue;
        }
        if (std.mem.indexOf(u8, line, "=")) |index| {
            const key = line[0..index];
            const value = line[index + 1 ..];
            try map.put(key, value);
        }
    }
    return .{
        .map = map,
    };
}

pub fn deinit(self: *Self) void {
    self.map.deinit();
}

pub fn get(self: Self, key: []const u8) ?[]const u8 {
    return self.map.get(key);
}
