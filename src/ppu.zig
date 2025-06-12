pub var vram: [0x2000]u8 = undefined; // 8000 - 9FFF
pub var oam: [0xA0]u8 = undefined; // FE00 - FE9F

pub const OAM = struct {
    y_pos: u8,
    x_pos: u8,
    tile_index: u8,
    flags: packed struct(u8) { priority: bool, y_flip: bool, x_flip: bool, dmg_palette: bool, _bank: bool, _cgb_palette: u3 },
};

pub var lcdc: u8 = undefined; //FF40 - LCD control
pub var stat: u8 = undefined; // FF41 - LCD status
pub var ly: u8 = 0; // FF44 - LCD Y coordinate [read-only]
pub var lyc: u8 = undefined; // FF45 - LY compare

// To sort
pub var scy: u8 = undefined;
pub var scx: u8 = undefined;
pub var lcd_control: u8 = undefined;
pub var bg_palette_data: u8 = undefined;
pub var obj0_palette_data: u8 = undefined;
pub var obj1_palette_data: u8 = undefined;
pub var wy: u8 = undefined;
pub var wx: u8 = undefined;
pub var dma_source_address: u8 = undefined;

var dot: u16 = 0;
pub fn step(cycles: u8) !void {
    for (0..cycles) |_| {
        for (0..4) |_| {
            switch (dot) {
                0...79 => {}, // OAM Scan
                172...456 => {},
                else => @panic(""),
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
