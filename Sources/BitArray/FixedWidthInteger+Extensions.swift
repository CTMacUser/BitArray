/*

  FixedWidthInteger+Extensions.swift
  BitArray

  Created by Daryle Walker on 1/29/18.
  Copyright (c) 2018 Daryle Walker.
  Distributed under the MIT License.

  Various properties and methods for BitArray's bit-twiddling.

 */


// MARK: Extensions for Unsigned Fixed-Width Integers

extension FixedWidthInteger where Self: UnsignedInteger {

    /**
     Returns this value except its bits are in reverse order.

     Taken from <https://graphics.stanford.edu/~seander/bithacks.html#BitReverseObvious>, the "Reverse bits the obvious way" section of "Bit Twiddling Hacks" by Sean Eron Anderson.

     - Returns: A bit-reversed rendition of `self`.
     */
    func bitReversed() -> Self {
        var result: Self = 0
        var mask: Self = 1
        while mask != 0 {
            defer { mask <<= 1 }

            result <<= 1
            if self & mask != 0 {
                result |= 1
            }
        }
        return result
    }

    /**
     Reverses the order of the stored bits.

     - Postcondition: The most- and least-significant bits swap values, the second-most- and second-least-significant bits swap values, *etc.*
     */
    mutating func bitReverse() {
        self = bitReversed()
    }

}

// MARK: Extensions for any Fixed-Width Integer

extension FixedWidthInteger {

    /**
     Returns a mask with only the given number of most-significant bits set.

     - Precondition: `0 <= count <= bitWidth`.

     - Parameter count: The number of high-order bits set to `1`.  All other bits are `0`.

     - Returns: The bitwise-complement of the lowest `bitWidth - count` bits being set.
     */
    static func highOrderBitsMask(count: Int) -> Self {
        precondition(count >= 0)

        return ~lowOrderBitsMask(count: bitWidth - count)
    }

    /**
     Pushes out and returns the receiver's high-order bits while the low-order bits move up to make room for bits inserted at the least-significant end.

     - Precondition: `0 <= count <= bitWidth`.

     - Parameter source: The value whose high-order bits will become the new low-order bits of `self`.
     - Parameter count: The number of bits from `source` pushed into `self`, and the number of bits formerly from `self` removed.

     - Returns: The previous value of `self` with the lower `bitWidth - count` bits zeroed out.

     - Postcondition:
        - `self >> count == oldSelf & ((2 ** (bitWidth - count)) - 1)`.
        - `self & ((2 ** count) - 1) == (source >> (bitWidth - count)) & ((2 ** count) - 1)`.
     */
    mutating func pushLowOrderBits(fromHighOrderBitsOf source: Self, count: Int) -> Self {
        switch count {
        case bitWidth:
            defer { self = source }
            return self
        case 1..<bitWidth:
            defer {
                self <<= count
                replaceBits(with: source >> (bitWidth - count), forOnly: Self.lowOrderBitsMask(count: count))
            }
            return self & Self.highOrderBitsMask(count: count)
        case 0:
            return 0
        default:
            preconditionFailure("Illegal replacing bit-width used")
        }
    }
    /**
     Pushes out and returns the receiver's low-order bits while the high-order bits move down to make room for bits inserted at the most-significant end.

     - Precondition: `0 <= count <= bitWidth`.

     - Parameter source: The value whose low-order bits will become the new high-order bits of `self`.
     - Parameter count: The number of bits from `source` pushed into `self`, and the number of bits formerly from `self` removed.

     - Returns: The previous value of `self` with the upper `bitWidth - count` bits zeroed out.

     - Postcondition:
        - `self << count == oldSelf & ~((2 ** count) - 1)`.
        - `(self >> (bitWidth - count)) & ((2 ** count) - 1 == source & ((2 ** count) - 1)`.
     */
    mutating func pushHighOrderBits(fromLowOrderBitsOf source: Self, count: Int) -> Self {
        switch count {
        case bitWidth:
            defer { self = source }
            return self
        case 1..<bitWidth:
            defer {
                self >>= count
                replaceBits(with: source << (bitWidth - count), forOnly: Self.highOrderBitsMask(count: count))
            }
            return self & Self.lowOrderBitsMask(count: count)
        case 0:
            return 0
        default:
            preconditionFailure("Illegal replacing bit-width used")
        }
    }

}
