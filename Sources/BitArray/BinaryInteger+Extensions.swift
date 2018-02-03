/*

  BinaryInteger+Extensions.swift
  BitArray

  Created by Daryle Walker on 1/29/18.
  Copyright (c) 2018 Daryle Walker.
  Distributed under the MIT License.

  Various properties and methods for BitArray's bit-twiddling.

 */


extension BinaryInteger {

    /**
     Returns a mask with only the given number of least-significant bits set.

     - Precondition: `count >= 0`.  `count` isn't so large that the result isn't representable.

     - Parameter count: The number of low-order bits to set to `1`.  All other bits are `0`.

     - Returns: One less than two to the `count` power.
     */
    static func lowOrderBitsMask(count: Int) -> Self {
        precondition(count >= 0)
        guard count > 0 else { return 0 }

        var mask: Self = 1
        mask <<= count - 1
        mask |= mask - 1
        return mask
    }

    /**
     Assigns the given source to the receiver, but only at the masked bit locations.

     - Parameter source: The new value(s) to assign to `self`'s bits.
     - Parameter mask: Which bits of `source` get assigned to `self`.  Only the bit positions set in `mask` have those corresponding bits in `self` get affected by `source`.

     - Returns: The previous values of the bits of `self` targeted by `mask`.  The untargeted bits are 0.

     - Postcondition:
        - `self & mask == source & mask`.
        - `self & ~mask == oldSelf & ~mask`.
     */
    @discardableResult
    mutating func replaceBits(with source: Self, forOnly mask: Self) -> Self {
        defer {
            self &= ~mask
            self |= source & mask
        }

        return self & mask
    }

}
