const std = @import("std");

pub var vram: [0x2000]u8 = .{0} ** 0x2000; // 8000 - 9FFF
pub var oam: union { u8: [0xA0]u8, struc: [40]OAM } = .{ .u8 = .{0} ** 160 }; // FE00 - FE9F

pub const OAM = packed struct(u32) {
    y_pos: u8,
    x_pos: u8,
    tile_index: u8,
    flags: packed struct(u8) { priority: bool, y_flip: bool, x_flip: bool, dmg_palette: bool, _bank: bool, _cgb_palette: u3 },
};

const LCDC = packed struct(u8) {
    bg_window__enable: bool = false,
    obj_enable: bool = false,
    obj_size: enum(u1) { @"8x8" = 0, @"8x16" = 1 } = .@"8x8",
    bg_tile_data_area: enum(u1) { @"8800-97FF" = 0, @"8000-8FFF" = 1 } = .@"8800-97FF",
    bg_tile_map_area: enum(u1) { @"9800-9BFF" = 0, @"9C00-9FFF" = 1 } = .@"9800-9BFF",
    window_enable: bool = false,
    window_tile_map_area: enum(u1) { @"8800-97FF" = 0, @"8000-8FFF" = 1 } = .@"8800-97FF",
    lcd_ppu_enable: bool = false,
};
pub var lcdc: LCDC = .{}; //FF40 - LCD control
pub var stat: u8 = 0x00; // FF41 - LCD status
pub var scy: u8 = 0x00; // FF42 - undefined
pub var scx: u8 = 0x00; // FF43 - undefined
pub var ly: u8 = 0x00; // FF44 - LCD Y coordinate [read-only]
pub var lyc: u8 = 0x00; // FF45 - LY compare
pub var bgp: u8 = 0x00; // FF47 - undefined
pub var obp0: u8 = 0x00; // FF48 - undefined
pub var obp1: u8 = 0x00; // FF49 - undefined
pub var wy: u8 = 0x00; // FF4A - undefined
pub var wx: u8 = 0x00; // FF4B - undefined

pub fn read_tile_pixel(tile_id: u8, x: u4, y: u4) u2 {
    const i: u16 = if (lcdc.bg_tile_data_area == .@"8800-97FF") 0x0800 else 0x0000;
    const ii = i + (@as(u16, tile_id) * 16) + y;
    const a: u2 = @intFromBool((vram[ii] & x) != 0);
    const b: u2 = @intFromBool((vram[ii + 8] & x) != 0);
    return a + (b << 1);
}
pub fn read_tile_map(x: u5, y: u5) u8 {
    const i: u16 = if (lcdc.bg_tile_map_area == .@"9800-9BFF") 0x1800 else 0x1C00;
    return vram[i + (@as(u16, y) * 0x20) + x];
}
pub fn read_background_pixel(x: u8, y: u8) u2 {}

pub fn fetch_from_oam() []OAM {}

const stdout = std.io.getStdOut();
var buf = std.io.bufferedWriter(stdout.writer());
const stdout_writer = buf.writer();
fn print_screenbuffer() void {
    _ = stdout_writer.write("\x1b[H") catch unreachable;
    var last_pixel: u2 = 0b00;
    for (screenbuffer) |a| {
        for (a) |pixel| {
            if (pixel == 0b01) {
                if (last_pixel != pixel) {
                    last_pixel = pixel;
                    _ = stdout_writer.write("\x1b[31m") catch unreachable;
                }
                _ = stdout_writer.write("██") catch unreachable;
            } else if (pixel == 0b10) {
                if (last_pixel != pixel) {
                    last_pixel = pixel;
                    _ = stdout_writer.write("\x1b[32m") catch unreachable;
                }
                _ = stdout_writer.write("██") catch unreachable;
            } else if (pixel == 0b11) {
                if (last_pixel != pixel) {
                    last_pixel = pixel;
                    _ = stdout_writer.write("\x1b[34m") catch unreachable;
                }
                _ = stdout_writer.write("██") catch unreachable;
            } else {
                _ = stdout_writer.write("  ") catch unreachable;
            }
        }
        _ = stdout_writer.write("\n") catch unreachable;
    }
    buf.flush() catch unreachable;
}

var dot: u16 = 0;
var screenbuffer: [144][160]u2 = .{.{0} ** 160} ** 144;
pub fn step(cycles: u8) !void {
    for (0..cycles) |_| {
        for (0..4) |_| {
            switch (ly) {
                0...143 => {
                    switch (dot) {
                        0...79 => {}, // OAM Scan
                        80...92 => {}, // Drawing pixels penalty
                        93...252 => {
                            const tile = read_tile_map(@truncate(@divFloor(dot - 93, 8)), @truncate(@divFloor(ly, 8)));

                            screenbuffer[ly][dot - 93] = read_tile_pixel(tile, @truncate(dot - 93), 0);
                        }, // Drawing pixels 2
                        253...457 => {}, // H-Blank
                        else => std.debug.panic("Tried to run dot {}", .{dot}),
                    }
                },
                144...153 => {},
                else => unreachable,
            }

            dot += 1;
            if (dot == 456) {
                ly += 1;
                dot = 0;
            }
            if (ly == 154) {
                ly = 0;
                print_screenbuffer();
            }
        }
    }
}
