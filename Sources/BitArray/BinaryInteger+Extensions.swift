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

}
