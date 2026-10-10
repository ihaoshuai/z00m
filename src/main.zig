const rl = @import("raylib");
const builtin = @import("builtin");
const std = @import("std");
const Screenshot = @import("screenshot.zig").Screenshot;

var g_zoom_rate: f32 = 3.0;
const ZOOM_INTERVAL: f32 = 0.5;
const ZOOM_MAX: f32 = 5.0;

const SHOW_RADIUS: f32 = 0.2;
const OUT_RADIUS: f32 = 0.5;

var g_is_running: bool = true;

const VS_PATH = "shader/basic.vs";
const FS_PATH = "shader/foucs.fs";

pub fn main() anyerror!void {
    const cur_frame = try Screenshot.getFrame();
    // std.debug.print("INFO: frame: {}x{}", .{ cur_frame.width, cur_frame.width });

    if(builtin.mode != .Debug) {
        _ = rl.changeDirectory(rl.getApplicationDirectory());
    }
    
    rl.setConfigFlags(.{ .fullscreen_mode = true });
    rl.initWindow(800, 600, "z00m");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    
    const img = rl.Image {
        .data = @ptrCast(cur_frame.rgba_buf),
        .width = @intCast(cur_frame.width),
        .height = @intCast(cur_frame.height),
        .mipmaps = 1,
        .format = rl.PixelFormat.uncompressed_r8g8b8a8
    };
    var tex: rl.Texture2D = try rl.loadTextureFromImage(img);
    defer rl.unloadTexture(tex);
    rl.genTextureMipmaps(&tex);
    rl.setTextureFilter(tex, .trilinear);
    cur_frame.free();

    const dest = rl.Rectangle.init(0.0, 0.0, @floatFromInt(rl.getRenderWidth()), @floatFromInt(rl.getRenderHeight()));
    var frame_count: u8 = 0;

    const shader = try rl.loadShader(VS_PATH, FS_PATH);
    defer rl.unloadShader(shader);
    const uniform_center_loc = rl.getShaderLocation(shader, "uCenter");
    const uniform_radius_loc = rl.getShaderLocation(shader, "uRadius");
    const uniform_out_radius_loc = rl.getShaderLocation(shader, "uOutRadius");
    // screen width/height
    const uniform_aspect_loc = rl.getShaderLocation(shader, "uAspect");
    const screen_aspect = dest.width/dest.height;
    rl.setShaderValue(shader, uniform_aspect_loc, &screen_aspect, .float);

    while (g_is_running) {        
        var zoom_pos = rl.getMousePosition();

        handleInput();

        // raylib will set mouse positon in center when start
        // manual fix mouse positon
        if (frame_count < 5) {
            rl.setMousePosition(cur_frame.mouse_x, cur_frame.mouse_y);
            frame_count += 1;
            zoom_pos = rl.Vector2.init(@floatFromInt(cur_frame.mouse_x), @floatFromInt(cur_frame.mouse_y));
        }

        const u_center = rl.Vector2 {
            .x = zoom_pos.x/dest.width,
            .y = zoom_pos.y/dest.height
        };
        rl.setShaderValue(shader, uniform_center_loc, &u_center, .vec2);
        rl.setShaderValue(shader, uniform_radius_loc, &(SHOW_RADIUS/g_zoom_rate), .float);
        rl.setShaderValue(shader, uniform_out_radius_loc, &(OUT_RADIUS/g_zoom_rate), .float);


        rl.beginDrawing();
            rl.clearBackground(.black);
            
            rl.beginShaderMode(shader);
                // beacause dest is equal to img size, so pass dest to getRenderRgion method directly
                rl.drawTexturePro(tex, getRenderRegion(dest, g_zoom_rate, zoom_pos), dest, .{.x = 0.0, .y = 0.0}, 0.0, .white);
            rl.endShaderMode();
        rl.endDrawing();

    }
}


fn getRenderRegion(source: rl.Rectangle, zoom_rate: f32, zoom_pos: rl.Vector2) rl.Rectangle {
    if(zoom_rate < 1)
        return source;

    return .{
        .x = zoom_pos.x - zoom_pos.x/zoom_rate,
        .y = zoom_pos.y - zoom_pos.y/zoom_rate,
        .height = source.height/zoom_rate,
        .width = source.width/zoom_rate,
    };
    
}

fn handleInput() void {
    const wheel_move = rl.getMouseWheelMove();
    if(wheel_move != 0) {
        g_zoom_rate += ZOOM_INTERVAL * wheel_move;
        if(g_zoom_rate < 1)
            g_zoom_rate = 1;
        if(g_zoom_rate > ZOOM_MAX)
            g_zoom_rate = ZOOM_MAX;
    }

    if(rl.isMouseButtonPressed(.right) or rl.isKeyPressed(.escape))
        g_is_running = false;
}