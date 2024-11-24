const std = @import("std");
const zap = @import("zap");
const MovieRouter = @import("routers/movie_router.zig");
const on_request = MovieRouter.on_request;

pub fn main() !void {
    var listener = zap.HttpListener.init(.{
        .port = 3000,
        .on_request = on_request,
        .log = true,
    });
    try listener.listen();

    std.debug.print("Listening on 0.0.0.0:3000\n", .{});

    zap.start(.{
        .threads = 2,
        .workers = 2,
    });
}
