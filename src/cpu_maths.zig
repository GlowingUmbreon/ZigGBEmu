const std = @import("std");

pub fn cast_int(comptime int_type: type, number: anytype) int_type {
    if (@TypeOf(number) == int_type) {
        return number;
    } else if (@typeInfo(int_type).int.bits < @typeInfo(@TypeOf(number)).int.bits) {
        return @truncate(number);
    } else {
        return @intCast(number);
    }
}

pub fn add_with_carry(comptime main_type: type, number1: anytype, number2: anytype) struct { main_type, bool, bool } {
    const half_type = @Type(.{ .int = .{ .bits = (@typeInfo(main_type).int.bits - 4), .signedness = .unsigned } });

    const result, const carry = @addWithOverflow(cast_int(main_type, number1), cast_int(main_type, number2));
    _, const half_carry = @addWithOverflow(cast_int(half_type, number1), cast_int(half_type, number2));

    return .{ result, carry == 1, half_carry == 1 };
}

pub fn sub_with_carry(comptime main_type: type, number1: anytype, number2: anytype) struct { main_type, bool, bool } {
    const half_type = @Type(.{ .int = .{ .bits = (@typeInfo(main_type).int.bits - 4), .signedness = .unsigned } });

    const result, const carry = @subWithOverflow(cast_int(main_type, number1), cast_int(main_type, number2));
    _, const half_carry = @subWithOverflow(cast_int(half_type, number1), cast_int(half_type, number2));

    return .{ result, carry == 1, half_carry == 1 };
}

const NumberWithCarryLSB = packed struct { carry: bool = undefined, number: u8 };
const NumberWithCarryMSB = packed struct { number: u8, carry: bool = undefined };
const Direction = enum { left, right };
pub fn shift(number: u8, dir: Direction) struct { u8, bool } {
    if (dir == .right) {
        var value: NumberWithCarryLSB = .{ .number = number };
        value = @bitCast(@as(u9, @bitCast(value)) >> 1);
        return .{ value.number, value.carry };
    } else {
        var value: NumberWithCarryMSB = .{ .number = number };
        value = @bitCast(@as(u9, @bitCast(value)) << 1);
        return .{ value.number, value.carry };
    }
}
pub fn shift_keep_bit(number: u8, carry: bool, dir: Direction) struct { u8, bool } {
    const n, const c = shift(number, carry, dir);
    if (dir == .right) {
        return .{ n ^ (number & 0b10000000), c };
    } else {
        return .{ n ^ (number & 0b00000001), c };
    }
}
pub fn rotate(number: u8, dir: Direction) struct { u8, bool } {
    if (dir == .right) {
        const value = std.math.rotr(u8, number, 1);
        return .{ value, (value & 0b00000001) != 0 };
    } else {
        const value = std.math.rotl(u8, number, 1);
        return .{ value, (value & 0b10000000) != 0 };
    }
}
pub fn rotate_through(number: u8, carry: bool, dir: Direction) struct { u8, bool } {
    if (dir == .right) {
        var value: NumberWithCarryLSB = .{ .carry = carry, .number = number };
        value = @bitCast(std.math.rotr(u9, @as(u9, @bitCast(value)), 1));
        return .{ value.number, value.carry };
    } else {
        var value: NumberWithCarryMSB = .{ .carry = carry, .number = number };
        value = @bitCast(std.math.rotl(u9, @as(u9, @bitCast(value)), 1));
        return .{ value.number, value.carry };
    }
}
