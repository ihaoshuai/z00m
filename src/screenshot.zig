const c = @cImport({
    @cInclude("X11/Xlib.h");
    @cInclude("X11/Xutil.h");
});

const std = @import("std");

pub const Screenshot = struct {
    rgba_buf: []u8,
    width: u32,
    height: u32,
    mouse_x: i32,
    mouse_y: i32,

    fn newEmpty(width: u32, height: u32) !Screenshot {
        return Screenshot{
            .rgba_buf =  try std.heap.page_allocator.alloc(u8, width * height * 4),
            .width = width,
            .height = height,
            .mouse_x = 0,
            .mouse_y = 0
        };
    }

    pub fn free(self: *const Screenshot) void {
        std.heap.page_allocator.free(self.rgba_buf);
    }

    pub fn getFrame() !Screenshot {
        const display = c.XOpenDisplay(null);
        if(display == null) {
            std.debug.print("ERROR: Failed to connect X server", .{});
            return error.CannotOpenDisplay;
        }
        defer _ = c.XCloseDisplay(display);

        const screen = c.DefaultScreen(display);
        const root = c.RootWindow(display, screen);

        var attr: c.XWindowAttributes = undefined;
        _ = c.XGetWindowAttributes(display, root, &attr);
        const width: u32 = @intCast(attr.width);
        const height: u32 = @intCast(attr.height);

        std.debug.print("monitor resolution: {}x{}\n", .{width, height});

        const ximage = c.XGetImage(display, root, 0, 0, width, height, c.AllPlanes, c.ZPixmap);
        if(ximage == null) {
            return error.ImageCaptureFailed;
        }
        defer _ = ximage.*.f.destroy_image.?(ximage);

        // BGRA => RGBA
        var screenshot = try Screenshot.newEmpty(width, height);
        const raw_bytes: [*]u8 = @ptrCast(ximage.*.data);
        var i: usize = 0;
        const total_bytes = width * height * 4;
        while (i < total_bytes) : (i += 4) {
            screenshot.rgba_buf[i+0] = raw_bytes[i+2]; //red
            screenshot.rgba_buf[i+1] = raw_bytes[i+1]; //green
            screenshot.rgba_buf[i+2] = raw_bytes[i+0]; //blue
            screenshot.rgba_buf[i+3] = raw_bytes[i+3]; //alpha
        }

        var root_return: c.Window = undefined;
        var child_return: c.Window = undefined;
        var root_x: c_int = undefined;
        var root_y: c_int = undefined;
        var win_x: c_int = undefined;
        var win_y: c_int = undefined;
        var mask_return: c_uint = undefined;

        const result = c.XQueryPointer(display, root, &root_return, &child_return, &root_x, &root_y, &win_x, &win_y, &mask_return);
        if (result != 1) {
            std.debug.print("Failed to get mouse positon, XQueryPoint return {}\n", .{result});
            return error.GetMousePositonFailed;
        }
        std.debug.print("mouse positon x: {}, y: {}\n", .{ root_x, root_y });

        screenshot.mouse_x = @intCast(root_x);
        screenshot.mouse_y = @intCast(root_y);

        return screenshot;
    
    }

};




