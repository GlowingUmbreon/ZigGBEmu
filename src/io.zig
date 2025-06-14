const std = @import("std");
const rom = @import("rom.zig");
const ppu = @import("ppu.zig");
const audio = @import("audio.zig");

pub const MBC = struct {
    read: fn (u16) u8,
    write: fn (u16, u8) void,
};
pub const mbcs = [_]MBC{
    @import("mbc/none.zig").mbc,
    @import("mbc/mbc1.zig").mbc,
};
pub const current_mbc: MBC = mbcs[1];

const Interrupts = packed struct(u8) {
    v_blank: bool = false,
    lcd: bool = false,
    timer: bool = false,
    serial: bool = false,
    joypad: bool = false,
    _: u3 = undefined,
};
pub var interrupt_enable: Interrupts = .{};
pub var interrupt_flag: Interrupts = .{};
var external_ram: [0x2000]u8 = undefined;
var high_ram: [127]u8 = undefined;
var wram: [2][0x1000]u8 = undefined;

var joypad: u8 = 0xff;
var div: u8 = undefined;
var tima: u8 = undefined;
var tma: u8 = undefined;
var tac: u8 = undefined;

var sb_buffer: [0x2048]u8 = undefined;
var sb_buffer_len: u32 = 0;

pub fn read(address: u16) u8 {
    return read1(address, false);
}

pub fn read1(address: u16, no_log: bool) u8 {
    //std.log.debug("r 0x{x:0>4}", .{address});
    const value: u8 = switch (address) {
        0x0000...0x7FFF => current_mbc.read(address),
        0x8000...0x9FFF => ppu.vram[address - 0x8000], // Video RAM
        0xA000...0xBFFF => current_mbc.read(address),
        0xC000...0xCFFF => wram[0][address - 0xC000], // Work RAM
        0xD000...0xDFFF => wram[1][address - 0xD000], // Work RAM
        0xE000...0xFDFF => unreachable, // Echo RAM
        0xFE00...0xFE9F => ppu.oam.u8[address - 0xFE00], // Object attribute memory
        0xFEA0...0xFEFF => unreachable, // Not Usable // TODO: Implement this
        0xFF00...0xFF7F => switch (address) { // I/O Ranges
            0xFF02 => unreachable, //TODO: FIX
            0xFF0F => @bitCast(interrupt_flag),
            0xFF10 => audio.NR10,
            0xFF11 => audio.NR11,
            0xFF12 => audio.NR12,
            0xFF13 => audio.NR13,
            0xFF14 => audio.NR14,
            0xFF15 => unreachable,
            0xFF16 => audio.NR21,
            0xFF17 => audio.NR22,
            0xFF18 => audio.NR23,
            0xFF19 => audio.NR24,
            0xFF1A => audio.NR30,
            0xFF1B => audio.NR31,
            0xFF1C => audio.NR32,
            0xFF1D => audio.NR33,
            0xFF1E => audio.NR34,
            0xFF1F => unreachable,
            0xFF20 => audio.NR41,
            0xFF21 => audio.NR41,
            0xFF22 => audio.NR41,
            0xFF23 => audio.NR44,
            0xFF24 => audio.NR50,
            0xFF25 => audio.NR51,
            0xFF26 => audio.NR52,
            0xFF27...0xFF2F => unreachable,
            0xFF40 => @bitCast(ppu.lcdc),
            0xFF44 => ppu.ly,
            0xFF4D => 0xFF, // CGB Only TODO: Default value?
            else => std.debug.panic("Attempted to read address {x}", .{address}),
        },
        0xFF80...0xFFFE => high_ram[address - 0xFF80], // High RAM
        0xFFFF => @bitCast(interrupt_enable), // Interrupt Enable register
    };
    _ = no_log;
    //if (!no_log) std.log.debug("r 0x{x:0>4} = 0x{x:0>2}", .{ address, value });
    return value;
}

pub fn read16(address: u16) u16 {
    return read(address) | (@as(u16, @intCast(read(address + 1))) << 8);
}

pub fn write(address: u16, value: u8) void {
    //std.log.debug("w 0x{x:0>4} = 0x{x:0>2}", .{ address, value });
    switch (address) {
        0x0000...0x7FFF => current_mbc.write(address, value),
        0x8000...0x9FFF => ppu.vram[address - 0x8000] = value, // Video RAM
        0xA000...0xBFFF => current_mbc.write(address, value),
        0xC000...0xCFFF => wram[0][address - 0xC000] = value, // Work RAM
        0xD000...0xDFFF => wram[1][address - 0xD000] = value, // Work RAM
        0xE000...0xFDFF => unreachable, // Echo RAM
        0xFE00...0xFE9F => ppu.oam.u8[address - 0xFE00] = value, // Object attribute memory
        0xFEA0...0xFEFF => {}, // Not Usable TODO: Does writing to this address do anything?
        0xFF00...0xFF7F => switch (address) { // I/O Ranges
            0xFF00 => joypad = value, // Controller
            0xFF01 => {
                // BLARG TEST OUTPUT
                //_ = std.io.getStdOut().write(&.{value}) catch undefined;
                //sb_buffer[sb_buffer_len] = value;
                //sb_buffer_len += 1;
            }, // TODO: This
            0xFF02 => {
                //std.log.warn("{s}", .{sb_buffer[0..sb_buffer_len]});
            }, // TODO: This
            0xFF03 => unreachable,
            0xFF04 => div = value,
            0xFF05 => tima = value,
            0xFF06 => tma = value,
            0xFF07 => tac = value,
            0xFF08...0xFF0E => unreachable,
            0xFF0F => interrupt_flag = @bitCast(value), // Interrupt flag

            // Audio
            0xFF10 => audio.NR10 = value,
            0xFF11 => audio.NR11 = value,
            0xFF12 => audio.NR12 = value,
            0xFF13 => audio.NR13 = value,
            0xFF14 => audio.NR14 = value,
            0xFF15 => unreachable,
            0xFF16 => audio.NR21 = value,
            0xFF17 => audio.NR22 = value,
            0xFF18 => audio.NR23 = value,
            0xFF19 => audio.NR24 = value,
            0xFF1A => audio.NR30 = value,
            0xFF1B => audio.NR31 = value,
            0xFF1C => audio.NR32 = value,
            0xFF1D => audio.NR33 = value,
            0xFF1E => audio.NR34 = value,
            0xFF1F => unreachable,
            0xFF20 => audio.NR41 = value,
            0xFF21 => audio.NR41 = value,
            0xFF22 => audio.NR41 = value,
            0xFF23 => audio.NR44 = value,
            0xFF24 => audio.NR50 = value,
            0xFF25 => audio.NR51 = value,
            0xFF26 => audio.NR52 = value,
            0xFF27...0xFF2F => unreachable,
            0xFF30...0xFF3F => unreachable, // TODO: implement this

            // Graphics
            0xFF40 => ppu.lcdc = @bitCast(value),
            0xFF41 => ppu.stat = @bitCast(value),
            0xFF42 => ppu.scy = value,
            0xFF43 => ppu.scx = value,
            0xFF44 => ppu.ly = value,
            0xFF45 => ppu.lyc = value,
            0xFF46 => {
                const source = @as(u16, @intCast(value)) * 0x100;
                for (0..0x9F) |offset| {
                    ppu.oam.u8[offset] = read(source + @as(u16, @intCast(offset)));
                }
            },
            0xFF47 => ppu.bgp = value,
            0xFF48 => ppu.obp0 = value,
            0xFF49 => ppu.obp1 = value,
            0xFF4A => ppu.wy = value,
            0xFF4B => ppu.wx = value,
            0xFF4C...0xFF4E => unreachable,
            0xFF4F => {}, // CGB
            0xFF50 => unreachable, // TODO: implement this
            0xFF51...0xFF55 => {}, // CGB only
            0xFF56...0xFF67 => unreachable,
            0xFF68...0xFF6B => {}, // CGB Only
            0xFF6C...0xFF6F => unreachable,
            0xFF70 => {}, // CGB Only
            0xFF71...0xFF7F => {}, // CGB Only
            else => std.debug.panic("Attempted to write address {x} with value {x}", .{ address, value }),
        },
        0xFF80...0xFFFE => high_ram[address - 0xFF80] = value, // High RAM
        0xFFFF => interrupt_enable = @bitCast(value), // Interrupt Enable register
    }
}
pub fn write_16(address: u16, value: u16) void {
    write(address, @truncate(value));
    write(address + 1, @truncate(value >> 8));
    //read(address) | (@as(u16, @intCast(read(address + 1))) << 8);
}
