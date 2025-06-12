const std = @import("std");
const lib = @import("ZigGBEmu_lib");

const rom = @import("rom.zig");
const cpu = @import("cpu.zig");
const io = @import("io.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    try rom.load_rom(allocator);

    //std.log.info("{any}", .{rom.header});
    const cwd = std.fs.cwd();
    const test_file = try cwd.openFile("./aaa/EpicLog.txt", .{ .mode = .read_only });
    const reader = test_file.reader();
    while (true) {
        try cpu.step(reader);

        if (cpu.ime_enabled) {
            if (io.interrupt_enable.v_blank and io.interrupt_flag.v_blank) {
                //std.log.warn("INTERUPT!", .{});
                cpu.ime_enabled = false;
                cpu.registers.u16.pc = 0x00;
            }
        }
    }
}
