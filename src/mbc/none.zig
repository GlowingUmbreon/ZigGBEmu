const rom = @import("../rom.zig");
const io = @import("../io.zig");

pub const mbc = io.MBC{
    .read = read,
    .write = write,
};

pub fn write(address: u16, value: u8) void {
    _ = value;
    switch (address) {
        0x0000...0x7FFF => {}, // R/O
        0xA000...0xBFFF => unreachable,
        else => unreachable,
    }
}

pub fn read(address: u16) u8 {
    return switch (address) {
        0x0000...0x7FFF => rom.rom[address],
        0xA000...0xBFFF => unreachable,
        else => unreachable,
    };
}
