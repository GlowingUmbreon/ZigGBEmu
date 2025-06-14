const std = @import("std");
const lib = @import("ZigGBEmu_lib");

const rom = @import("rom.zig");
const cpu = @import("cpu.zig");
const io = @import("io.zig");
const ppu = @import("ppu.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    try rom.load_rom(allocator, "./tools/BlarggTestRoms/04-op r,imm.gb");

    const cwd = std.fs.cwd();
    const test_file = try cwd.openFile("./tools/BlarggTestRomsLogs/EpicLog.txt", .{ .mode = .read_only });
    const reader = test_file.reader();
    while (true) {
        const cycles = try cpu.step(reader);
        _ = cycles;
        //try ppu.step(cycles);

        if (cpu.ime_enabled) {
            if (io.interrupt_enable.v_blank and io.interrupt_flag.v_blank) {
                //std.log.warn("INTERUPT!", .{});
                cpu.ime_enabled = false;
                cpu.registers.u16.pc = 0x00;
            }
        }
    }
}
