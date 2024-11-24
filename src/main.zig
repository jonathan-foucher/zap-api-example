const std = @import("std");
const zap = @import("zap");
const dotenv = @import("utils/dotenv.zig");
const MovieRouter = @import("routers/movie_router.zig");
const on_request = MovieRouter.on_request;

const DEFAULT_HTTP_PORT: usize = 8080;

pub fn main() !void {
    var env = try dotenv.init(std.heap.page_allocator);
    defer env.deinit();
    const HTTP_PORT: usize = std.fmt.parseInt(usize, env.get("HTTP_PORT").?, 10) catch DEFAULT_HTTP_PORT;

    var listener = zap.HttpListener.init(.{
        .port = HTTP_PORT,
        .on_request = on_request,
        .log = true,
    });
    try listener.listen();

    std.debug.print("Listening on 0.0.0.0:{d}\n", .{ HTTP_PORT });

    zap.start(.{
        .threads = 2,
        .workers = 2,
    });
}
