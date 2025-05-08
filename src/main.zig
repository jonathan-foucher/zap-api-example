const std = @import("std");
const zap = @import("zap");
const dotenv = @import("utils/dotenv.zig");
const DatabaseConnection = @import("database/database_connection.zig");
const DB = DatabaseConnection.DB;
const MovieRouter = @import("routers/movie_router.zig");
const on_request = MovieRouter.on_request;
const c = @cImport({
    @cInclude("libpq-fe.h");
});

const DEFAULT_HTTP_PORT: usize = 8080;

pub var db: DB = undefined;
pub const allocator = std.heap.page_allocator;

pub fn main() !void {
    var env = try dotenv.init(allocator);
    defer env.deinit();
    const HTTP_PORT: usize = std.fmt.parseInt(usize, env.get("HTTP_PORT").?, 10) catch DEFAULT_HTTP_PORT;
    const DATABASE_URL: [:0]const u8 = std.fmt.allocPrintZ(allocator, "{s}", .{env.get("DATABASE_URL").?}) catch |err| {
        std.debug.print("{any}\n", .{ err });
        return;
    };

    db = DB.init(DATABASE_URL) catch return;
    defer db.deinit();

    try db.exec(
        \\ create table if not exists movie (
        \\     id integer primary key,
        \\     title varchar(50) not null,
        \\     release_date date not null
        \\ );
    );

    const save_prep = c.PQprepare(
        db.conn,
        "save_movie",
        \\ insert into movie (id, title, release_date)
        \\ values ($1, $2, $3)
        \\ on conflict(id) do update set
        \\ title = EXCLUDED.title,
        \\ release_date = EXCLUDED.release_date;
        ,
        3,
        null
    );
    if (c.PQresultStatus(save_prep) != c.PGRES_COMMAND_OK) {
        std.debug.print("prepare save_movie failed, err: {s}\n", .{ c.PQerrorMessage(db.conn) });
        return error.prepareSave;
    }
    defer c.PQclear(save_prep);

    const delete_prep = c.PQprepare(
        db.conn,
        "delete_movie_by_id",
        "delete from movie where id = $1;",
        1,
        null
    );
    if (c.PQresultStatus(delete_prep) != c.PGRES_COMMAND_OK) {
        std.debug.print("prepare delete_movie_by_id failed, err: {s}\n", .{ c.PQerrorMessage(db.conn) });
        return error.prepareDelete;
    }
    defer c.PQclear(delete_prep);

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
