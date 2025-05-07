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
};
