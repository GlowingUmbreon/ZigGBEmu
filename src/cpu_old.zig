///////////////////////////
pub fn read_imm8(inc_pc: bool) u8 {
    const imm8: u8 = io.read(registers.u16.pc);
    if (inc_pc) registers.u16.pc += 1;
    return imm8;
}
pub fn read_imm8_signed(inc_pc: bool) i8 {
    const imm8: i8 = @bitCast(io.read(registers.u16.pc));
    if (inc_pc) registers.u16.pc += 1;
    return imm8;
}
pub fn read_imm16(inc_pc: bool) u16 {
    const imm16: u16 = io.read(registers.u16.pc) | (@as(u16, @intCast(io.read(registers.u16.pc + 1))) << 8);
    if (inc_pc) registers.u16.pc += 2;
    return imm16;
}

//
//pub fn read() @This {

//}

// A read/writer for a u8 value
pub const U8 = union(enum) {
    pub const R8 = enum(u3) {
        b = 0,
        c = 1,
        d = 2,
        e = 3,
        h = 4,
        l = 5,
        hl = 6,
        a = 7,

        pub fn use_enum(this: @This()) U8 {
            return U8{ .r8 = this };
        }

        pub fn read(opcode: u8, start: u8) U8 {
            const value = (opcode >> @truncate(start)) & ~(~@as(u8, 0) << @truncate((3 - start + 1)));
            return U8{ .r8 = @enumFromInt(@as(u3, @truncate(value))) };
        }
    };

    r8: R8,
    imm8: u16,
    imm8_ptr: u16,

    pub fn imm8_ptr_operand() U8 {
        cpu.registers.u16.pc += 1;
        return U8{ .imm8_ptr = cpu.registers.u16.pc - 1 };
    }
    pub fn imm8_operand() U8 {
        cpu.registers.u16.pc += 1;
        return U8{ .imm8 = cpu.registers.u16.pc - 1 };
    }

    pub fn get(this: @This()) u8 {
        return switch (this) {
            .r8 => |v| switch (v) {
                .b => cpu.registers.u8.b,
                .c => cpu.registers.u8.c,
                .d => cpu.registers.u8.d,
                .e => cpu.registers.u8.e,
                .h => cpu.registers.u8.h,
                .l => cpu.registers.u8.l,
                .a => cpu.registers.u8.a,
                .hl => io.read(cpu.registers.u16.hl),
            },
            .imm8 => |v| io.read(v),
            .imm16_ptr => |v| io.read(io.read(v)),
        };
    }

    pub fn set(this: @This(), value: u8) void {
        return switch (this) {
            .r8 => |v| switch (v) {
                .b => cpu.registers.u8.b = value,
                .c => cpu.registers.u8.c = value,
                .d => cpu.registers.u8.d = value,
                .e => cpu.registers.u8.e = value,
                .h => cpu.registers.u8.h = value,
                .l => cpu.registers.u8.l = value,
                .a => cpu.registers.u8.a = value,
                .hl => io.write(cpu.registers.u16.hl, value),
            },
            .imm8 => |_| std.debug.panic("Cannot write to imm8", .{}),
            .imm16_ptr => |v| io.write(io.read(v), value),
        };
    }
};

pub const U16 = union(enum) {
    pub const R16 = enum(u2) {
        bc = 0,
        de = 1,
        hl = 2,
        sp = 3,

        pub fn read_from_reg(this: @This()) U8 {
            return U8{ .r8 = this };
        }

        pub fn read(opcode: u8, start: u8) U8 {
            const value = (opcode >> @truncate(start)) & ~(~@as(u8, 0) << @truncate((2 - start + 1)));
            return U8{ .r8 = @enumFromInt(@as(u3, @truncate(value))) };
        }
    };

    r16: R16,
    imm16: u16,

    pub fn get(this: @This()) u8 {
        return switch (this) {
            .r8 => |r8| switch (r8) {
                .bc => cpu.registers.u16.bc,
                .de => cpu.registers.u16.de,
                .hl => cpu.registers.u16.hl,
                .sp => cpu.registers.u16.bc,
            },
        };
    }

    pub fn set(this: @This(), value: u8) void {
        return switch (this) {
            .r8 => |r8| switch (r8) {
                .bc => cpu.registers.u16.bc = value,
                .de => cpu.registers.u16.de = value,
                .hl => cpu.registers.u16.hl = value,
                .sp => cpu.registers.u16.bc = value,
            },
        };
    }
};
