const std = @import("std");
const c = @cImport({
    @cInclude("libpq-fe.h");
});

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
};
