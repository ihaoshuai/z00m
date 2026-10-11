
const std = @import("std");

const LOCK_FILE_PATH = "/tmp/z00m.pid";

var lock_file: ?std.Io.File = null;
var threaded: std.Io.Threaded = .init_single_threaded;
const io = threaded.io();

pub fn lock() !bool {
    lock_file = std.Io.Dir.cwd().createFile(io,  LOCK_FILE_PATH, .{
        .read = true,
        .truncate = false,
    }) catch |err| {
        std.debug.print("Failed to create/open file: {}\n", .{ err });
        return error.FileOpenFailed;
    };

    const file = lock_file.?;
    const locked = file.tryLock(io, .exclusive) catch false;

    if (!locked) {
        var buf: [32]u8 = undefined;
        var file_buffer: [32]u8 = undefined;
        var reader = file.reader(io, &file_buffer);
        const bytes_read = reader.interface.readSliceShort(&buf) catch 0;
        const pid_str = std.mem.trim(u8, buf[0..bytes_read], " \n\r\x00");

        if (std.fmt.parseInt(std.posix.pid_t, pid_str, 10)) |old_pid| {
            std.debug.print("Find the old instance: PID: {}, exiting\n", .{old_pid});   
            // 向旧进程发送 SIGTERM 终止信号
            std.posix.kill(old_pid, std.posix.SIG.TERM) catch |kill_err| {
                std.debug.print("Failed to send signal: {}\n", .{kill_err});
            };
        } else |_| {
            std.debug.print("no effective pid\n", .{});
        }
        file.close(io);
        return false;
    }



    var pid_buf: [32]u8 = undefined;
    const pid_str = try std.fmt.bufPrint(&pid_buf, "{d}\n", .{std.os.linux.getpid()});
    var write_buf: [64]u8 = undefined;
    var file_writer = file.writer(io, &write_buf);
    try file_writer.interface.writeAll(pid_str);
    try file_writer.interface.flush();

    return true;
}

pub fn unlock() void {
    if(lock_file) |file| {
        file.close(io);
        std.Io.Dir.cwd().deleteFile(io, LOCK_FILE_PATH) catch {};
    }
}