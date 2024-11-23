const std = @import("std");
const zap = @import("zap");

fn on_request(request: zap.Request) void {
    if (request.path != null) {
        if (std.mem.eql(u8, request.path.?, "/api/movies")) {
            if (request.methodAsEnum() == .GET) {
                std.debug.print("Get all movies\n", .{});
                request.sendBody("Get all movies") catch return;
            }

            if (request.methodAsEnum() == .POST) {
                std.debug.print("Post movie id=, title='' and relase_date=\n", .{});
                request.setStatus(.ok);
                return;
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
