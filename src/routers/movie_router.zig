const zap = @import("zap");
const std = @import("std");
const MovieModel = @import("../models/movie.zig");
const Movie = MovieModel.Movie;

pub fn on_request(request: zap.Request) void {
    if (request.path) |path| {
        if (std.mem.eql(u8, path, "/api/movies")) {
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

        const start_path = "/api/movies/";
        if (std.mem.startsWith(u8, path, start_path)) {
            if (request.methodAsEnum() == .DELETE) {
                const movie_id: i32 = std.fmt.parseInt(i32, path[start_path.len ..], 10) catch {
                    request.setStatus(.bad_request);
                    return;
                };
                std.debug.print("Delete movie with id {d}\n", .{ movie_id });
                request.setStatus(.ok);
                return;
            }
        }
    }

    request.setStatus(.not_found);
}
