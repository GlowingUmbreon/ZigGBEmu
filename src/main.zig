const std = @import("std");
const lib = @import("ZigGBEmu_lib");

const rom = @import("rom.zig");
const cpu = @import("cpu.zig");
const io = @import("io.zig");
const ppu = @import("ppu.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    try rom.load_rom(allocator, "./tools/BlarggTestRoms/02-interrupts.gb");
    //if (rom.header.cartridge_type != .rom_only) std.debug.panic("cartridge_type is {any}", .{rom.header.cartridge_type});

    while (true) {
        const cycles = try cpu.step();
        _ = cycles;
        //try ppu.step(cycles);

        if (cpu.ime_enabled) {
            std.log.info("IME ENABLED", .{});
            if (io.interrupt_enable.v_blank and io.interrupt_flag.v_blank) {
                std.log.warn("INTERUPT!", .{});
                cpu.ime_enabled = false;
                cpu.registers.u16.pc = 0x00;
            }
        }
    }
}
