const std = @import("std");
const lib = @import("ZigGBEmu_lib");

const rom = @import("rom.zig");
const cpu = @import("cpu.zig");
const io = @import("io.zig");
const ppu = @import("ppu.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    try rom.load_rom(allocator, "./tools/tetris.gb");
    //if (rom.header.cartridge_type != .rom_only) std.debug.panic("cartridge_type is {any}", .{rom.header.cartridge_type});

    while (true) {
        const cycles = try cpu.step();
        try ppu.step(cycles);

        if (cpu.ime_enabled) {
            if (io.interrupt_enable.v_blank and io.interrupt_flag.v_blank) {
                cpu.ime_enabled = false;
                cpu.push_stack16(cpu.registers.u16.pc);
                cpu.registers.u16.pc = 0x40;
            } else if (io.interrupt_enable.lcd and io.interrupt_flag.lcd) {
                cpu.ime_enabled = false;
                cpu.push_stack16(cpu.registers.u16.pc);
                cpu.registers.u16.pc = 0x48;
            } else if (io.interrupt_enable.timer and io.interrupt_flag.timer) {
                cpu.ime_enabled = false;
                cpu.push_stack16(cpu.registers.u16.pc);
                cpu.registers.u16.pc = 0x50;
            } else if (io.interrupt_enable.serial and io.interrupt_flag.serial) {
                cpu.ime_enabled = false;
                cpu.push_stack16(cpu.registers.u16.pc);
                cpu.registers.u16.pc = 0x58;
            } else if (io.interrupt_enable.joypad and io.interrupt_flag.joypad) {
                cpu.ime_enabled = false;
                cpu.push_stack16(cpu.registers.u16.pc);
                cpu.registers.u16.pc = 0x60;
            }
        }
    }
}
