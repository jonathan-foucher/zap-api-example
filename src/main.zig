const std = @import("std");
const zap = @import("zap");
const MovieModel = @import("models/movie.zig");
const Movie = MovieModel.Movie;

fn on_request(request: zap.Request) void {
    if (request.path != null) {
        if (std.mem.eql(u8, request.path.?, "/api/movies")) {
            if (request.methodAsEnum() == .GET) {
                std.debug.print("Get all movies\n", .{});
                request.sendBody("Get all movies") catch return;
            }

            if (request.methodAsEnum() == .POST) {           
                if (request.body) |body| {
                    const movie_opt: ?std.json.Parsed(Movie) = std.json.parseFromSlice(Movie, std.heap.page_allocator, body, .{}) catch null;
                    if (movie_opt) |movie| {
                        std.debug.print("validate\n", .{});
                        defer movie.deinit();
                        std.debug.print("Post movie id={d}, title='{s}' and relase_date={s}\n", .{ movie.value.id, movie.value.title, movie.value.release_date });
                        request.setStatus(.ok);
                        return;
                    }
                }
            }
        }

        if (std.mem.startsWith(u8, request.path.?, "/api/movies/")) {
            if(request.methodAsEnum() == .DELETE) {
                std.debug.print("Delete movie with id \n", .{});
                request.setStatus(.ok);
                return;
            }
        }
    }

    return request.setStatus(.not_found);
}

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
