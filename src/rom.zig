// https://gbdev.io/pandocs/The_Cartridge_Header.html
// https://github.com/osnr/tetris/blob/master/tetris.asm
const std = @import("std");

const CartridgeType = enum(u8) {
    rom_only = 0x00,
    mbc1 = 0x01,
    mbc1_ram = 0x02,
    mbc1_ram_battery = 0x03,
    mbc2 = 0x05,
    mbc2_battery = 0x06,
    rom_ram = 0x08,
    rom_ram_battery = 0x09,
    mmm01 = 0x0B,
    mmm01_ram = 0x0C,
    mmoc_ram_battery = 0x0D,
    mbc3_timer_battery = 0x0F,
    mbc3_timer_ram_battery = 0x10,
    mbc3 = 0x11,
    mbc3_ram = 0x12,
    mbc3_ram_battery = 0x13,
    mbc5 = 0x19,
    mbc5_ram = 0x1A,
    mbc5_ram_battery = 0x1B,
    mbc5_rumble = 0x1C,
    mbc5_rumble_ram = 0x1D,
    mbc5_rumble_ram_battery = 0x1E,
    mbc6 = 0x20,
    mbc7_sensor_rumble_ram_battery = 0x22,
    pocket_camera = 0xFC,
    bandai_tama5 = 0xFD,
    huc3 = 0xFE,
    huc1_ram_battery = 0xFF,
    _,
};
const RomSize = enum(u8) {
    Kib32 = 0x00,
    Kib64 = 0x01,
    Kib128 = 0x02,
    Kib256 = 0x03,
    Kib512 = 0x04,
    Mib1 = 0x05,
    Mib2 = 0x06,
    Mib4 = 0x07,
    Mib8 = 0x08,
    // Unofficial
    @"1.1 MiB" = 0x52,
    @"1.2 MiB" = 0x80,
    @"1.5 MiB" = 0x96,
    _,
};
const RamSize = enum(u8) {
    None = 0x00,
    Kib8 = 0x02,
    Kib32 = 0x03,
    Kib64 = 0x05,
    Kib128 = 0x04,
    _,
};
pub const Header = extern struct {
    entry_point: u32, //[4]u8
    nintendo_logo: [48]u8, // [48]u8
    title: [16]u8, // [16]u8
    //manufactuer_code: u32, //[4]u8
    //cgb_flag: u8,
    new_licensee_code: [2]u8, // [2]u8
    sgb_flag: u8,
    cartridge_type: CartridgeType,
    rom_size: RomSize,
    ram_size: RamSize,
    destination_code: u8,
    old_licensee_code: u8,
    rom_version_numer: u8,
    header_checksum: u8,
    global_checksum: u16,
};

pub var rom: [*]u8 = undefined;
pub var header: *Header = undefined;

pub fn load_rom(allocator: std.mem.Allocator) !void {
    const cwd = std.fs.cwd();
    const file = try cwd.openFile("./06-ld r,r.gb", .{ .mode = .read_only });
    const file_reader = file.reader();
    const bytes = try file_reader.readAllAlloc(allocator, 0x800000);
    rom = bytes.ptr;
    header = @ptrFromInt(@intFromPtr(rom) + 0x100);
}
