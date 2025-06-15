const rom = @import("../rom.zig");
const io = @import("../io.zig");

var ram_bank_number: u16 = 1;

pub const mbc = io.MBC{
    .read = read,
    .write = write,
};

pub fn write(address: u16, value: u8) void {
    switch (address) {
        0x0000...0x1FFF => unreachable,
        0x2000...0x3FFF => ram_bank_number = value,
        0x4000...0x5FFF => unreachable,
        0x6000...0x7FFF => unreachable,
        else => unreachable,
    }
}

pub fn read(address: u16) u8 {
    return switch (address) {
        0x0000...0x3FFF => rom.rom[address],
        0x4000...0x7FFF => rom.rom[(ram_bank_number * 0x4000) + (address - 0x4000)],
        0xA000...0xBFFF => unreachable,
        else => unreachable,
    };
}
