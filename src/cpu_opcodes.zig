// TO SORT //

// call cond imm16 - 110xx100
// 0b11000100, 0b11001100, 0b11010100, 0b11011100 => |v| {
//     const operands: packed struct(u8) { _1: u3, cond: Condition, _2: u3 } = @bitCast(v);
//     const imm16 = read_imm16(true);

//     if (operands.cond.check()) {
//         push_stack16(cpu.registers.u16.pc);
//         cpu.registers.u16.pc = imm16;
//     }
// },

// ldh a, [c] - 11110010
// 0b11110010 => {
//     const address = 0xFF00 +% @as(u16, @intCast(cpu.registers.u8.c));
//     cpu.registers.u8.a = io.read(address);
// },

// ldh [c], a - 11100010
// 0b11100010 => {
//     io.write(0xFF00 + @as(u16, @intCast(cpu.registers.u8.c)), cpu.registers.u8.a);
// },

// To Sort //

///////////
// Other //
///////////

// //   dec r16 - 00xx1011
// 0b00001011,
// 0b00011011,
// 0b00101011,
// 0b00111011,
// => |v| {
//     const operands: packed struct(u8) { _1: u4, r16: R16, _2: u2 } = @bitCast(v);
//     const r16 = operands.r16;

//     r16.set(r16.get() -% 1);
// },
// //    sub a, r8 - 10010xxx
// 0b10010000...0b10010111 => |v| {
//     const operands: packed struct(u8) { operand: R8, _1: u5 } = @bitCast(v);
//     const result = @subWithOverflow(cpu.registers.u8.a, operands.operand.get());
//     cpu.registers.u8.a = result[0];
//     cpu.registers.flags.z = result[0] == 0;
//     cpu.registers.flags.n = true;
//     //cpu.registers.flags.h = TODO: this
//     cpu.registers.flags.c = result[1] == 1;
// },

// // sbc a, r8 - 10011xxx
// 0b10011000...0b10011111 => |v| {
//     const operands: packed struct(u8) { operand: R8, _1: u5 } = @bitCast(v);
//     const result = @subWithOverflow(cpu.registers.u8.a, operands.operand.get() + @as(u1, @bitCast(cpu.registers.flags.c)));
//     cpu.registers.u8.a = result[0];
//     cpu.registers.flags.z = result[0] == 0;
//     cpu.registers.flags.n = true;
//     //cpu.registers.flags.h = TODO: this
//     cpu.registers.flags.c = result[1] == 1;
// },

// // and a, r8 - 10100xxx
// 0b10100000...0b10100111 => |v| {
//     const operands: packed struct(u8) { operand: R8, _1: u5 } = @bitCast(v);
//     cpu.registers.u8.a &= operands.operand.get();
//     cpu.registers.flags.z = cpu.registers.u8.a == 0;
//     cpu.registers.flags.n = false;
//     cpu.registers.flags.h = true;
//     cpu.registers.flags.c = false;
// },

// // xor a, r8 - 10101xxx
// 0b10101000...0b10101111 => |v| xor(R8.read(v, 0).get()),

// //rst tgt3 11xxx111
// 0b11000111, 0b11001111, 0b11010111, 0b11011111, 0b11100111, 0b11101111, 0b11110111, 0b11111111 => |v| {
//     const operands: packed struct(u8) { _1: u3, tgt3: u3, _2: u2 } = @bitCast(v);
//     push_stack16(cpu.registers.u16.pc);
//     cpu.registers.u16.pc = @as(u16, @intCast(operands.tgt3)) * 0x8;
// },

// 0b00011111 => {
//     const operands: packed struct(u8) { _1: u5, r8: R8 } = .{ ._1 = undefined, .r8 = R8.a };

//     var value = U8_Carry_R{ .struc = .{
//         .u8 = operands.r8.get(),
//         .carry = cpu.registers.flags.c,
//     } };
//     value.u9 = std.math.rotr(u9, value.u9, 1);
//     operands.r8.set(value.struc.u8);

//     cpu.registers.flags.z = value.struc.u8 == 0;
//     cpu.registers.flags.n = false;
//     cpu.registers.flags.h = false;
//     cpu.registers.flags.c = value.struc.carry;
// },

// Prefix
//0xCB =>  {

//},
