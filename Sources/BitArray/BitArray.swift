/*

  BitArray.swift
  BitArray

  Created by Daryle Walker on 1/29/18.
  Copyright (c) 2018 Daryle Walker.
  Distributed under the MIT License.

  A collection that stores Boolean elements bit-packed in words.

 */


// MARK: Bit-Packed Boolean Array

/// A collection like `Array<Bool>`, but stores its elements compactly as single bits within words.
public struct BitArray {

    /// How bits are packed together.
    typealias Word = UInt
    /// How long collections of packed-bits are handled.
    typealias WordArray = [Word]

    /// The storage for the packed bits.
    private(set) var bits: WordArray
    /// How many bits remaining after every previous word is full.
    private(set) var remnantCount: Int

    /**
     Creates an instance whose bits are sourced from the given sequence of words.

     This is the primary initializer; all others call this one, directly or indirectly.

     If `bitCount` is not divided by `Word.bitWidth` evenly, then only some of the bits of the last non-ignored word are used.  Whether the most- or least-significant bits of that last word are counted depends on `bitIterationDirection`.

     - Precondition:
        - The number of elements in `coreWords` times the bit-width per word is at least `bitCount`.
        - `bitCount >= 0`.

     - Parameter coreWords: The sequence of words that is the source of the stored bits.  The bits from a given word are mapped to being earlier in the overall sequence than the bits from any later word.
     - Parameter bitCount: The number of bits to store.  Any bits in `words` after this cut-off are ignored.
     - Parameter bitIterationDirection: Whether the high-order bits of each word are the ones that should be considered earliest for the overall sequence, or should intra-word iteration start at the low-order bits instead.

     - Postcondition:
        - `count == bitCount`.
        - `bits.count == ceil(bitCount / Word.bitWidth)`.
        - If *s* is a `Sequence` that vends the exploded bits from the elements of `coreWords` (in `bitIterationDirection` order), then `s.elementsEqual(self)`.
     */
    init<S>(coreWords: S, bitCount: Int, bitIterationDirection: EndianTraversal) where S: Sequence, S.Element == Word {
        precondition(bitCount >= 0)

        // Copy the words, and compute the remnant length.
        let (bq, br) = bitCount.quotientAndRemainder(dividingBy: Word.bitWidth)
        let expectedWordCount = bq + br.signum()
        bits = WordArray(coreWords)
        remnantCount = br
        precondition(expectedWordCount <= bits.count)

        // Reverse the bits' storage if needed, and zero-out any bits past any remnant.
        bits.removeLast(bits.count - expectedWordCount)
        switch bitIterationDirection {
        case .hi2lo:
            // Storage order is already most-significant bit to lowest.
            break
        case .lo2hi:
            // Reverse the order of the bits.
            for i in bits.indices {
                bits[i].bitReverse()
            }
        }
        if remnantCount != 0 {
            bits[bits.index(before: bits.endIndex)] &= Word.highOrderBitsMask(count: remnantCount)
        }
    }

}
