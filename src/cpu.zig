const std = @import("std");
const io = @import("io.zig");

pub var ime_enabled = false;
pub var registers: packed union {
    u16: packed struct { // Double
        af: u16 = 0x01B0,
        bc: u16 = 0x0013,
        de: u16 = 0x00d8,
        hl: u16 = 0x014D,
        sp: u16 = 0xFFFE,
        pc: u16 = 0x0100,
    },
    u8: packed struct { // Single
        f: u8,
        a: u8,
        c: u8,
        b: u8,
        e: u8,
        d: u8,
        l: u8,
        h: u8,
    },
    flags: packed struct { // Flags
        _: u4, // Always 0
        c: bool, // Carry
        h: bool, // Half-Carry
        n: bool, // Subtraction
        z: bool, // Zero
    },
} = .{ .u16 = .{} };

pub fn set_flags(z: ?bool, n: ?bool, h: ?bool, c: ?bool) void {
    if (z) |v| registers.flags.z = v;
    if (n) |v| registers.flags.n = v;
    if (h) |v| registers.flags.h = v;
    if (c) |v| registers.flags.c = v;
}

pub fn step(reader: std.fs.File.Reader) !u8 {
    const cycles: u8 = 1; // TODO: Set a sane default
    const opcode = io.read(registers.u16.pc);

    if (registers.u16.pc != 0x000) { // Debug
        std.log.debug("A: {X:0>2} F: {X:0>2} B: {X:0>2} C: {X:0>2} D: {X:0>2} E: {X:0>2} H: {X:0>2} L: {X:0>2} SP: {X:0>4} PC: {X:0>2}:{X:0>4} ({X:0>2} {X:0>2} {X:0>2} {X:0>2})", .{ registers.u8.a, registers.u8.f, registers.u8.b, registers.u8.c, registers.u8.d, registers.u8.e, registers.u8.h, registers.u8.l, registers.u16.sp, 0x00, registers.u16.pc, io.read1(registers.u16.pc, true), io.read1(registers.u16.pc + 1, true), io.read1(registers.u16.pc + 2, true), io.read1(registers.u16.pc + 3, true) });
        var buffer: [83]u8 = undefined;
        var buffer2: [83]u8 = undefined;
        _ = try reader.readAll(&buffer);
        _ = try std.fmt.bufPrint(&buffer2, "A: {X:0>2} F: {X:0>2} B: {X:0>2} C: {X:0>2} D: {X:0>2} E: {X:0>2} H: {X:0>2} L: {X:0>2} SP: {X:0>4} PC: {X:0>2}:{X:0>4} ({X:0>2} {X:0>2} {X:0>2} {X:0>2})\n", .{ registers.u8.a, registers.u8.f, registers.u8.b, registers.u8.c, registers.u8.d, registers.u8.e, registers.u8.h, registers.u8.l, registers.u16.sp, 0x00, registers.u16.pc, io.read1(registers.u16.pc, true), io.read1(registers.u16.pc + 1, true), io.read1(registers.u16.pc + 2, true), io.read1(registers.u16.pc + 3, true) });
        if (!std.mem.eql(u8, &buffer, &buffer2)) {
            std.log.err("{s} was expected", .{buffer});
            @panic("Test failed");
        }
    }
    registers.u16.pc += 1;
    switch (opcode) {
        // Block 0 //

        // nop - 00000000
        inline 0x00 => {},
        //
        //ld r16, imm16 - 00xx0001
        inline 0b00000001, 0b00010001, 0b00100001, 0b00110001 => |v| {
            const r16 = read_r16(v, 4);
            const imm16: u16 = read_imm16(true);

            r16.set(imm16);
        },
        // ld [r16mem], a - 00xx0010
        inline 0b00000010, 0b00010010, 0b00100010, 0b00110010 => |v| {
            const r16 = read_r16_mem(v, 4);

            io.write(r16.get(), registers.u8.a);
            r16.increment();
        },
        // ld a, [r16mem] - 00xx1010
        inline 0b00001010, 0b00011010, 0b00101010, 0b00111010 => |v| {
            const r16 = read_r16_mem(v, 4);

            registers.u8.a = io.read(r16.get());
            r16.increment();
        },
        // ld [imm16], sp - 00001000
        inline 0b00001000 => {
            const imm16 = read_imm16(true);

            io.write_16(imm16, registers.u16.sp);
        },
        //
        // inc r16 - 00xx0011
        inline 0b00000011, 0b00010011, 0b00100011, 0b00110011 => |v| {
            const r16 = read_r16(v, 4);

            r16.set(r16.get() +% 1);
        },
        // dec r16 - 00xx1011
        inline 0b00001011, 0b00011011, 0b00101011, 0b00111011 => |v| {
            const r16 = read_r16(v, 4);

            r16.set(r16.get() -% 1);
        },
        // add hl, r16 - 00xx1001
        inline 0b00001001, 0b00011001, 0b00101001, 0b00111001 => |v| {
            const r16 = read_r16(v, 4);
            const result, const carry = @addWithOverflow(registers.u16.hl, r16.get());
            _, const half_carry = @addWithOverflow(@as(u12, @truncate(registers.u16.hl)), @as(u12, @truncate(r16.get())));
            registers.u16.hl = result;

            set_flags(null, false, half_carry == 1, carry == 1);
        },
        //
        // inc r8 - 00xxx100
        inline 0b00000100, 0b00001100, 0b00010100, 0b00011100, 0b00100100, 0b00101100, 0b00110100, 0b00111100 => |v| {
            const r8 = read_r8(v, 3);

            const result = r8.get() +% 1;
            _, const half_carry = @addWithOverflow(@as(u4, @truncate(r8.get())), 1);
            r8.set(result);

            set_flags(result == 0, false, half_carry == 1, null);
        },
        // dec r8 - 00xxx101
        inline 0b00000101, 0b00001101, 0b00010101, 0b00011101, 0b00100101, 0b00101101, 0b00110101, 0b00111101 => |v| {
            const r8 = read_r8(v, 3);

            const result = r8.get() -% 1;
            _, const half_carry = @subWithOverflow(@as(u4, @truncate(r8.get())), 1);
            r8.set(result);

            set_flags(r8.get() == 0, true, half_carry == 1, null);
        },
        //
        // ld r8, imm8 - 00xxx110
        inline 0b00000110, 0b00001110, 0b00010110, 0b00011110, 0b00100110, 0b00101110, 0b00110110, 0b00111110 => |v| {
            const r8 = read_r8(v, 3);
            const imm8 = read_imm8(true);

            r8.set(imm8);
        },
        //
        // rlca - 00000111
        inline 0b00000111 => {
            var value = U8_Carry_L{ .struc = .{
                .u8 = registers.u8.a,
                .carry = registers.flags.c,
            } };
            value.u9 = std.math.rotl(u9, value.u9, 1);
            registers.u8.a = value.struc.u8;

            set_flags(false, false, false, value.struc.carry);
        },
        // rrca - 00001111
        inline 0b00001111 => {
            var value = U8_Carry_R{ .struc = .{
                .u8 = registers.u8.a,
                .carry = registers.flags.c,
            } };
            value.u9 = std.math.rotr(u9, value.u9, 1);
            registers.u8.a = value.struc.u8;

            set_flags(false, false, false, value.struc.carry);
        },
        // rla
        // rra - 00011111
        inline 0b00011111 => {
            var value = U8_Carry_R{ .struc = .{
                .u8 = registers.u8.a,
                .carry = registers.flags.c,
            } };
            value.u9 = std.math.rotr(u9, value.u9, 1);
            registers.u8.a = value.struc.u8;

            set_flags(false, false, false, value.struc.carry);
        },
        // daa - 00100111
        inline 0b00100111 => {
            var adjustment: u8 = 0;
            if (registers.flags.n) {
                if (registers.flags.h) adjustment += 0x06;
                if (registers.flags.c) adjustment += 0x60;
                registers.u8.a -%= adjustment;
            } else {
                if (registers.flags.h or registers.u8.a & 0x0F > 0x09) adjustment += 0x06;
                if (registers.flags.c or registers.u8.a > 0x99) {
                    adjustment += 0x60;
                    registers.flags.c = true;
                }
                registers.u8.a +%= adjustment;
            }
            registers.flags.h = false;
            registers.flags.z = registers.u8.a == 0;
        },
        // cpl
        // scf
        // ccf - 00111111
        inline 0b00111111 => {
            set_flags(null, false, false, !registers.flags.c);
        },
        //
        // jr imm8 - 00011000
        inline 0b00011000 => {
            const imm8: i8 = @bitCast(read_imm8(true));
            if (imm8 > 0) {
                registers.u16.pc +%= @intCast(imm8);
            } else {
                registers.u16.pc -%= @abs(imm8);
            }
        },
        // jr cond, imm8 - 001xx000
        inline 0b00100000, 0b00101000, 0b00110000, 0b00111000 => |v| {
            const cond = read_condition(v, 3);
            const imm8: i8 = @bitCast(read_imm8(true));

            if (cond.check()) {
                if (imm8 > 0) {
                    registers.u16.pc +%= @intCast(imm8);
                } else {
                    registers.u16.pc -%= @abs(imm8);
                }
            }
        },
        //
        // stop

        // Block  1/

        // ld r8, r8 - 01xxxyyy
        inline 0b01000000...0b01110101, 0b01110111...0b01111111 => |v| {
            const source = read_r8(v, 0);
            const dest = read_r8(v, 3);
            dest.set(source.get());
        },
        //
        // halt

        // Block 2 //

        // add a, r8 - 10000xxx
        inline 0b10000000...0b10000111 => |v| {
            const r8 = read_r8(v, 0);
            const result, const carry = @addWithOverflow(registers.u8.a, r8.get());
            _, const half_carry = @addWithOverflow(@as(u4, @truncate(registers.u8.a)), r8.get());
            registers.u8.a = result;
            set_flags(result == 0, false, half_carry == 1, carry == 1);
        },
        // adc a, r8 - 10001xxx
        inline 0b10001000...0b10001111 => |v| {
            const r8 = read_r8(v, 0);
            const result, const carry = @addWithOverflow(registers.u8.a, r8.get());
            _, const half_carry = @addWithOverflow(@as(u4, @truncate(registers.u8.a)), r8.get());
            set_flags(result == 0, false, half_carry == 1, carry == 1);
        },
        // sub a, r8 - 10010xxx
        inline 0b10010000...0b10010111 => |v| {
            const r8 = read_r8(v, 0);
            const result, const carry = @subWithOverflow(registers.u8.a, r8.get());
            _, const half_carry = @subWithOverflow(registers.u8.a % 0x10, r8.get() % 0x10);
            registers.u8.a = result;
            set_flags(result == 0, true, half_carry == 1, carry == 1);
        },
        // sbc a, r8 - 10011xxx
        inline 0b10011000...0b10011111 => |v| {
            const r8 = read_r8(v, 0);
            const result, const carry = @subWithOverflow(registers.u8.a, r8.get());
            _, const half_carry = @subWithOverflow(registers.u8.a % 0x10, r8.get() % 0x10);
            set_flags(result == 0, true, half_carry == 1, carry == 1);
        },
        // and a, r8
        // xor a, r8 - 10101xxx
        inline 0b10101000...0b10101111 => |v| {
            const r8 = read_r8(v, 0);
            registers.u8.a ^= r8.get();
            set_flags(registers.u8.a == 0, false, false, false);
        },
        // or a, r8 - 10110xxx
        inline 0b10110000...0b10110111 => |v| {
            const r8 = read_r8(v, 0);
            registers.u8.a |= r8.get();
            set_flags(registers.u8.a == 0, false, false, false);
        },
        // cp a, r8 - 10111xxx
        inline 0b10111000...0b10111111 => |v| {
            const r8 = read_r8(v, 0);
            const result, const carry = @subWithOverflow(registers.u8.a, r8.get());
            _, const half_carry = @subWithOverflow(registers.u8.a % 0x10, r8.get() % 0x10);

            set_flags(result == 0, true, half_carry == 1, carry == 1);
        },

        // Block 3 //

        // add a, imm8 - 11000110
        inline 0b11000110 => {
            const imm8 = read_imm8(true);
            const result, const carry = @addWithOverflow(registers.u8.a, imm8);
            _, const half_carry = @addWithOverflow(@as(u4, @truncate(registers.u8.a)), @as(u4, @truncate(imm8)));
            registers.u8.a = result;
            set_flags(result == 0, false, half_carry == 1, carry == 1);
        },
        // adc a, imm8 - 11001110
        inline 0b11001110 => {
            const imm8 = read_imm8(true) +% @as(u1, @bitCast(registers.flags.c));
            const result, const carry = @addWithOverflow(registers.u8.a, imm8);
            _, const half_carry = @addWithOverflow(@as(u4, @truncate(registers.u8.a)), @as(u4, @truncate(imm8)));
            registers.u8.a = result;
            set_flags(result == 0, false, half_carry == 1, carry == 1);
        },
        // sub a, imm8
        inline 0b11010110 => {
            const imm8 = read_imm8(true);
            const result, const carry = @subWithOverflow(registers.u8.a, imm8);
            _, const half_carry = @subWithOverflow(registers.u8.a % 0x10, imm8 % 0x10);
            registers.u8.a = result;
            set_flags(result == 0, true, half_carry == 1, carry == 1);
        },
        // sbc a, imm8
        // and a, imm8 - 11100110
        inline 0b11100110 => {
            const imm8 = read_imm8(true);
            registers.u8.a &= imm8;
            set_flags(registers.u8.a == 0, false, true, false);
        },
        // xor a, imm8 - 11101110
        inline 0b11101110 => {
            const imm8 = read_imm8(true);
            registers.u8.a ^= imm8;
            set_flags(registers.u8.a == 0, false, false, false);
        },
        // or a, imm8
        // cp a, imm8 - 11111110
        inline 0b11111110 => {
            const imm8 = read_imm8(true);
            const result, const overflow = @subWithOverflow(registers.u8.a, imm8);
            _, const half_carry = @subWithOverflow(registers.u8.a % 0x10, imm8 % 0x10);
            set_flags(result == 0, true, half_carry == 1, overflow == 1);
        },
        //
        // ret cond - 110xx000
        inline 0b11000000, 0b11001000, 0b11010000, 0b11011000 => |v| {
            const condition = read_condition(v, 3);
            if (condition.check()) registers.u16.pc = pop_stack16();
        },
        // ret - 11001001
        inline 0b11001001 => {
            registers.u16.pc = pop_stack16();
        },
        // reti
        // jp cond, imm16 - 110xx010
        inline 0b11000010, 0b11001010, 0b11010010, 0b11011010 => |v| {
            const imm16: u16 = read_imm16(true);
            const condition = read_condition(v, 3);
            if (condition.check()) registers.u16.pc = imm16;
        },
        // jp imm16 - 11000011
        inline 0b11000011 => {
            const imm16: u16 = read_imm16(true);
            registers.u16.pc = imm16;
        },
        // jp hl - 11101001
        inline 0b11101001 => {
            registers.u16.pc = registers.u16.hl;
        },
        // call cond, imm16 -- 110xx100
        inline 0b11000100, 0b11001100, 0b11010100, 0b11011100 => |v| {
            const condition = read_condition(v, 3);
            const imm16 = read_imm16(true);
            if (condition.check()) {
                push_stack16(registers.u16.pc);
                registers.u16.pc = imm16;
            }
        },
        // call imm16 - 11001101
        inline 0b11001101 => {
            const imm16 = read_imm16(true);
            push_stack16(registers.u16.pc);
            registers.u16.pc = imm16;
        },
        // rst tgt3
        //
        // pop r16stk - 11xx0001
        inline 0b11000001, 0b11010001, 0b11100001, 0b11110001 => |v| {
            const r16 = read_r16_stk(v, 4);
            r16.set(pop_stack16());
        },
        // push r16stk - 11xx0101
        inline 0b11000101, 0b11010101, 0b11100101, 0b11110101 => |v| {
            const r16 = read_r16_stk(v, 4);
            push_stack16(r16.get());
        },
        //
        // ldh [c], a
        // ldh [imm8], a - 11100000
        inline 0b11100000 => {
            const imm8 = read_imm8(true);
            const address: u16 = 0xFF00 + @as(u16, @intCast(imm8));
            io.write(address, registers.u8.a);
        },
        // ld [imm16], a - 11101010
        inline 0b11101010 => {
            const imm16 = read_imm16(true);
            io.write(imm16, registers.u8.a);
        },
        // ldh a, [c]
        // ldh a, [imm8] - 11110000
        inline 0b11110000 => {
            const imm8 = read_imm8(true);
            const address: u16 = 0xFF00 + @as(u16, @intCast(imm8));
            registers.u8.a = io.read(address);
        },
        // ld a, [imm16] - 11111010
        inline 0b11111010 => {
            const imm16 = read_imm16(true);
            registers.u8.a = io.read(imm16);
        },
        // add sp, imm8 - 11101000
        inline 0b11101000 => {
            const imm8_u = read_imm8(true);
            const imm8: i8 = @bitCast(imm8_u);
            var result: u16, var carry: u1, var half_carry: u1 = .{ 0, 0, 0 };

            if (imm8 < 0) {
                result, _ = @subWithOverflow(registers.u16.sp, @abs(imm8));
            } else {
                result, _ = @addWithOverflow(registers.u16.sp, @abs(imm8));
            }
            _, carry = @addWithOverflow(@as(u8, @truncate(registers.u16.sp)), imm8_u);
            _, half_carry = @addWithOverflow(@as(u4, @truncate(registers.u16.sp)), @as(u4, @truncate(imm8_u)));
            registers.u16.sp = result;
            set_flags(false, false, half_carry == 1, carry == 1);
        },
        // ld hl, sp + imm8 - 11111000
        inline 0b11111000 => {
            const imm8_u = read_imm8(true);
            const imm8: i8 = @bitCast(imm8_u);
            var result: u16, var carry: u1, var half_carry: u1 = .{ 0, 0, 0 };

            if (imm8 < 0) {
                result, _ = @subWithOverflow(registers.u16.sp, @abs(imm8));
            } else {
                result, _ = @addWithOverflow(registers.u16.sp, @abs(imm8));
            }
            _, carry = @addWithOverflow(@as(u8, @truncate(registers.u16.sp)), imm8_u);
            _, half_carry = @addWithOverflow(@as(u4, @truncate(registers.u16.sp)), @as(u4, @truncate(imm8_u)));
            registers.u16.hl = result;
            set_flags(false, false, half_carry == 1, carry == 1);
        },
        // ld sp, hl
        inline 0b11111001 => {
            registers.u16.sp = registers.u16.hl;
        },
        // di - 11110011
        inline 0b11110011 => {
            ime_enabled = false;
        },
        // ei - 11110011
        inline 0b11111011 => {
            ime_enabled = true;
        },

        // Prefix //
        inline 0b11001011 => switch (read_imm8(true)) {
            // rr r8 - 00011xxx
            inline 0b00011000...0b00011111 => |v| {
                const r8 = read_r8(v, 0);

                var value = U8_Carry_R{ .struc = .{
                    .u8 = r8.get(),
                    .carry = registers.flags.c,
                } };
                value.u9 = std.math.rotr(u9, value.u9, 1);
                r8.set(value.struc.u8);

                set_flags(value.struc.u8 == 0, false, false, value.struc.carry);
            },
            // rrc r8
            // rl r8
            // rr r8
            // sla r8
            // sra r8
            // swap r8 - 00110xxx
            inline 0b00110000...0b00110111 => |v| {
                const r8 = read_r8(v, 0);

                const value = r8.get();
                const result = (value << 4) | (value >> 4);
                r8.set(result);

                set_flags(result == 0, false, false, false);
            },
            // srl r8 - 00111xxx
            inline 0b00111000...0b00111111 => |v| {
                const r8 = read_r8(v, 0);

                var value = U8_Carry_R{ .struc = .{
                    .u8 = r8.get(),
                    .carry = registers.flags.c,
                } };

                value.u9 >>= 1;
                r8.set(value.struc.u8);

                set_flags(r8.get() == 0, false, false, value.struc.carry);
            },
            //
            // bit b3, r8 - 0b01xxxyyy
            inline 0b01000000...0b01111111 => |v| {
                const u = read_u(v, 3, u3);
                const r8 = read_r8(v, 0);

                const z = r8.get() & (1 << u);

                set_flags(z == 0, false, true, null);
            },
            // res b3, r8
            // set b3, r8
            else => |v| std.debug.panic("Unimplemented PREFIX OPCode 0x{x}", .{v}),
        },

        // invalid opcodes
        0xD3, 0xDB, 0xDD, 0xE3, 0xE4, 0xEB, 0xEC, 0xED, 0xF4, 0xFC, 0xFD => std.debug.panic("Invalid OPCode 0x{x}", .{opcode}),
        else => std.debug.panic("Unimplemented OPCode 0x{x}", .{opcode}),
    }
    registers.flags._ = 0;
    return cycles;
}

// Carry maths
const U8_Carry_R = packed union { u9: u9, struc: packed struct { carry: bool, u8: u8 } };
const U8_Carry_L = packed union { u9: u9, struc: packed struct { u8: u8, carry: bool } };

// Stack Control
pub fn push_stack(value: u8) void {
    registers.u16.sp -%= 1;
    io.write(registers.u16.sp, value);
}
pub fn push_stack16(value: u16) void {
    registers.u16.sp -%= 2;
    io.write_16(registers.u16.sp, value);
}

pub fn pop_stack() u8 {
    const value = io.read(registers.u16.sp);
    registers.u16.sp +%= 1;
    return value;
}
pub fn pop_stack16() u16 {
    const value = io.read16(registers.u16.sp);
    registers.u16.sp +%= 2;
    return value;
}

// Operands Control
pub inline fn read_u(comptime value: u8, comptime lsb: u8, comptime Type: type) Type {
    return @truncate((value >> @truncate(lsb)) & ~(~@as(u8, 0) << @bitSizeOf(Type)));
}
pub inline fn read_r8(comptime opcode: u8, comptime lsb: u8) R8 {
    const value = (opcode >> @truncate(lsb)) & 0b00000111;
    return @enumFromInt(@as(u3, @truncate(value)));
}
pub inline fn read_r16(comptime opcode: u8, comptime lsb: u8) R16 {
    const value = (opcode >> @truncate(lsb)) & 0b00000011;
    return @enumFromInt(@as(u2, @truncate(value)));
}
pub inline fn read_r16_stk(comptime opcode: u8, comptime lsb: u8) R16stk {
    const value = (opcode >> @truncate(lsb)) & 0b00000011;
    return @enumFromInt(@as(u2, @truncate(value)));
}
pub inline fn read_r16_mem(comptime opcode: u8, comptime lsb: u8) R16mem {
    const value = (opcode >> @truncate(lsb)) & 0b00000011;
    return @enumFromInt(@as(u2, @truncate(value)));
}
pub inline fn read_condition(comptime opcode: u8, comptime lsb: u8) Condition {
    const value = (opcode >> @truncate(lsb)) & 0b00000011;
    return @enumFromInt(@as(u2, @truncate(value)));
}
pub fn read_imm8(inc_pc: bool) u8 {
    const imm8: u8 = io.read(registers.u16.pc);
    if (inc_pc) registers.u16.pc += 1;
    return imm8;
}
pub fn read_imm16(inc_pc: bool) u16 {
    const imm16: u16 = io.read(registers.u16.pc) | (@as(u16, @intCast(io.read(registers.u16.pc + 1))) << 8);
    if (inc_pc) registers.u16.pc += 2;
    return imm16;
}

const R16mem = enum(u2) {
    bc = 0,
    de = 1,
    hli = 2,
    hld = 3,

    pub inline fn get(this: R16mem) u16 {
        return switch (this) {
            .bc => registers.u16.bc,
            .de => registers.u16.de,
            .hli => registers.u16.hl,
            .hld => registers.u16.hl,
        };
    }

    pub inline fn increment(this: R16mem) void {
        return switch (this) {
            .hli => registers.u16.hl += 1,
            .hld => registers.u16.hl -= 1,
            else => undefined,
        };
    }
};
const R16 = enum(u2) {
    bc = 0,
    de = 1,
    hl = 2,
    sp = 3,

    pub inline fn get(comptime this: R16) u16 {
        return @field(registers.u16, @tagName(this));
    }
    pub inline fn set(comptime this: R16, value: u16) void {
        @field(registers.u16, @tagName(this)) = value;
    }
};
const R16stk = enum(u2) {
    bc,
    de,
    hl,
    af,

    pub inline fn get(comptime this: R16stk) u16 {
        return @field(registers.u16, @tagName(this));
    }
    pub inline fn set(comptime this: R16stk, value: u16) void {
        @field(registers.u16, @tagName(this)) = value;
    }
};
pub const R8 = enum(u3) {
    b = 0,
    c = 1,
    d = 2,
    e = 3,
    h = 4,
    l = 5,
    hl = 6,
    a = 7,

    pub fn get(comptime this: R8) u8 {
        return switch (this) {
            .b => registers.u8.b,
            .c => registers.u8.c,
            .d => registers.u8.d,
            .e => registers.u8.e,
            .h => registers.u8.h,
            .l => registers.u8.l,
            .a => registers.u8.a,
            .hl => io.read(registers.u16.hl),
        };
    }
    pub fn set(comptime this: R8, value: u8) void {
        return switch (this) {
            .b => registers.u8.b = value,
            .c => registers.u8.c = value,
            .d => registers.u8.d = value,
            .e => registers.u8.e = value,
            .h => registers.u8.h = value,
            .l => registers.u8.l = value,
            .a => registers.u8.a = value,
            .hl => io.write(registers.u16.hl, value),
        };
    }
};
const Condition = enum(u2) {
    nz = 0,
    z = 1,
    nc = 2,
    c = 3,

    pub inline fn check(comptime this: Condition) bool {
        return switch (this) {
            .nz => !registers.flags.z,
            .z => registers.flags.z,
            .nc => !registers.flags.c,
            .c => registers.flags.c,
        };
    }
};
