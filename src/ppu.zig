const std = @import("std");

pub var vram: [0x2000]u8 = undefined; // 8000 - 9FFF
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
    bg_tile_map_area: enum(u1) { @"8800-97FF" = 0, @"8000-8FFF" = 1 } = .@"8800-97FF",
    bg_window_tile_data_area: enum(u1) { @"9800-9BFF" = 0, @"9C00-9FFF" = 1 } = .@"9800-9BFF",
    window_enable: bool = false,
    window_tile_map_area: enum(u1) { @"8800-97FF" = 0, @"8000-8FFF" = 1 } = .@"8800-97FF",
    lcd_ppu_enable: bool = false,
};
pub var lcdc: LCDC = .{}; //FF40 - LCD control
pub var stat: u8 = undefined; // FF41 - LCD status
pub var scy: u8 = undefined; // FF42 - undefined
pub var scx: u8 = undefined; // FF43 - undefined
pub var ly: u8 = 0x90; // FF44 - LCD Y coordinate [read-only]
pub var lyc: u8 = undefined; // FF45 - LY compare
pub var bgp: u8 = undefined; // FF47 - undefined
pub var obp0: u8 = undefined; // FF48 - undefined
pub var obp1: u8 = undefined; // FF49 - undefined
pub var wy: u8 = undefined; // FF4A - undefined
pub var wx: u8 = undefined; // FF4B - undefined

pub fn read_tile_data() void {}

pub fn fetch_from_oam() []OAM {}

var dot: u16 = 0;
pub fn step(cycles: u8) !void {
    for (0..cycles) |_| {
        for (0..4) |_| {
            switch (dot) {
                0...79 => {}, // OAM Scan
                160...171 => {}, // Drawing pixels penalty
                172...456 => {}, // Drawing pixels 2
                else => std.debug.panic("Tried to run dot {}", .{dot}),
            }

            ly += 1;
            if (dot == 456) {
                ly += 1;
                dot = 0;
            }
            if (ly == 154) ly = 0;
        }
    }
}
