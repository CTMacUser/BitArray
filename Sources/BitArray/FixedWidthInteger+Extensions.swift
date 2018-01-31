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

}
