const std = @import("std");
const c = @cImport({
    @cInclude("libpq-fe.h");
});
const Main = @import("../main.zig");
const MovieModel = @import("../models/movie.zig");
const Movie = MovieModel.Movie;

pub const DB = struct {
    conn: *c.PGconn,

    pub fn init(conn_info: [:0]const u8) !DB {
        const conn = c.PQconnectdb(conn_info);
        if (c.PQstatus(conn) != c.CONNECTION_OK) {
            std.debug.print("Connect failed, err: {s}\n", .{c.PQerrorMessage(conn)});
            return error.connect;
        }
        return DB{ .conn = conn.? };
    }

    pub fn deinit(self: DB) void {
        c.PQfinish(self.conn);
    }

    pub fn exec(self: DB, query: [:0]const u8) !void {
        const result = c.PQexec(self.conn, query);
        defer c.PQclear(result);

        if (c.PQresultStatus(result) != c.PGRES_COMMAND_OK) {
            std.debug.print("exec query failed, query:{s}, err: {s}\n", .{ query, c.PQerrorMessage(self.conn) });
            return error.Exec;
        }
    }

    pub fn get_all_movies(self: DB) ![]Movie {
        const query = "select * from movie;";

        const result = c.PQexec(self.conn, query);
        defer c.PQclear(result);

        if (c.PQresultStatus(result) != c.PGRES_TUPLES_OK) {
            std.debug.print("exec query failed, query:{s}, err: {s}\n", .{ query, c.PQerrorMessage(self.conn) });
            return error.queryTable;
        }

        const n_rows = c.PQntuples(result);
        const movies = try Main.allocator.alloc(Movie, @intCast(n_rows));

        for (0..@intCast(n_rows)) |row| {
            const id = std.mem.span(c.PQgetvalue(result, @intCast(row), 0));
            const title = std.mem.span(c.PQgetvalue(result, @intCast(row), 1));
            const release_date = std.mem.span(c.PQgetvalue(result, @intCast(row), 2));

            movies[row].id = std.fmt.parseInt(i32, id, 10) catch |err| {
                std.debug.print("Failed to parse the number: {}\n", .{ err });
                return err;
            };
            movies[row].title = title;
            movies[row].release_date = release_date;
        }
        return movies;
    }

    pub fn save_movie(self: DB, movie: Movie) !void {
        const str_id: []const u8 = try std.fmt.allocPrint(Main.allocator, "{d}", .{ movie.id });
        const str_title: []const u8 = try std.fmt.allocPrint(Main.allocator, "{s}", .{ movie.title });
        const str_release_date: []const u8 = try std.fmt.allocPrint(Main.allocator, "{s}", .{ movie.release_date });

        const result = c.PQexecPrepared(
            self.conn,
            "save_movie",
            3,
            &[_][*c]const u8 { @ptrCast(str_id), @ptrCast(str_title), @ptrCast(str_release_date) },
            &[_]c_int { @intCast(str_id.len), @intCast(str_title.len), @intCast(str_release_date.len) },
            &[_]c_int { 0, 0, 0 },
            0
        );
        defer c.PQclear(result);
        if (c.PQresultStatus(result) != c.PGRES_TUPLES_OK) {
            std.debug.print("exec save_movie failed, err: {s}\n", .{ c.PQresultErrorMessage(result) });
            return error.SaveMovieById;
        }
    }

    pub fn delete_movie(self: DB, movie_id: i32) !void {
        const str_movie_id: []const u8 = try std.fmt.allocPrint(Main.allocator, "{d}", .{ movie_id });
        const result = c.PQexecPrepared(
            self.conn,
            "delete_movie_by_id",
            1,
            &[_][*c]const u8 { @ptrCast(str_movie_id) },
            &[_]c_int { @intCast(str_movie_id.len) },
            &[_]c_int { 0 },
            0
        );
        defer c.PQclear(result);
        if (c.PQresultStatus(result) != c.PGRES_TUPLES_OK) {
            std.debug.print("exec delete_movie_by_id failed, err: {s}\n", .{ c.PQresultErrorMessage(result) });
            return error.DeleteMovieById;
        }
    }
};
