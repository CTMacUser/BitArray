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

// MARK: Splitting & Joining

extension BitArray {

    /// The index of the word holding any remnant bits (i.e. the last word unless no remnant is needed).
    var remnantWordIndex: WordArray.Index? {
        return remnantCount != 0 ? bits.index(before: bits.endIndex) : nil
    }
    /// The count of fully used words, i.e. before any remnant.
    var wholeWordCount: WordArray.IndexDistance {
        return bits.distance(from: bits.startIndex, to: remnantWordIndex ?? bits.endIndex)
    }

    /**
     Returns a new instance with the prefix of the receiver.

     - Precondition: `0 <= bitCount <= count`.

     - Parameter bitCount: The number of bits copied from the beginning of `self`.

     - Returns: `BitArray(self.prefix(bitCount))`.
     */
    func head(bitCount: Int) -> BitArray {
        let (bq, br) = bitCount.quotientAndRemainder(dividingBy: Word.bitWidth)
        precondition((bq, br) <= (wholeWordCount, remnantCount))

        return BitArray(coreWords: bits, bitCount: bitCount, bitIterationDirection: .hi2lo)
    }
    /**
     Removes the given number of elements from the start of the receiver.

     - Precondition: `0 <= bitCount <= count`.

     - Parameter bitCount: The number of bits removed from the beginning of `self`.

     - Postcondition: Same as `self.removeFirst(bitCount)`.
     */
    mutating func truncateHead(bitCount: Int) {
        let (bq, br) = bitCount.quotientAndRemainder(dividingBy: Word.bitWidth)
        precondition(bitCount >= 0)
        precondition((bq, br) <= (wholeWordCount, remnantCount))

        // Remove the whole words.
        bits.removeFirst(bq)

        // Remove the head's remnant by moving all the later bits forward.
        var pushedOutBits: Word = 0
        for i in bits.indices.reversed() {
            pushedOutBits = bits[i].pushLowOrderBits(fromHighOrderBitsOf: pushedOutBits, count: br)
        }

        // Purge extraneous word if the shift-forward moved the tail's remnant, or created one.
        let hadRemnant = remnantCount != 0
        remnantCount -= br
        if remnantCount <= 0 {
            if hadRemnant {
                let extraneousWord = bits.removeLast()
                assert(extraneousWord == 0)
            } else {
                assert((remnantCount < 0) == (br > 0))
            }
            if remnantCount < 0 {
                remnantCount += Word.bitWidth
            }
        }
    }
    /**
     Inserts the elements of `head` to the start of the receiver.

     - Parameter head: The source of the new elements.

     - Postcondition:
        - `count == oldSelf.count + head.count`.
        - `self.prefix(head.count) == head`.
        - `self.suffix(oldSelf.count) == oldSelf`.
     */
    mutating func prependHead(_ head: BitArray) {
        guard !head.bits.isEmpty else { return }
        guard !bits.isEmpty else {
            bits.replaceSubrange(bits.startIndex..., with: head.bits)
            remnantCount = head.remnantCount
            return
        }

        // Move existing bits back for the head's remnant.
        if let hrwi = head.remnantWordIndex {
            assert(head.remnantCount > 0)

            // Make room for a new word if both instances remnants are long enough.
            if remnantCount == 0 || head.remnantCount + remnantCount > Word.bitWidth {
                bits.append(0)
            }

            // Copy the head's remnant in while shifting the existing bits back.
            var pushedOutBits = head.bits[hrwi] >> (Word.bitWidth - head.remnantCount)
            for i in bits.indices {
                pushedOutBits = bits[i].pushHighOrderBits(fromLowOrderBitsOf: pushedOutBits, count: head.remnantCount)
            }
            remnantCount += head.remnantCount
            remnantCount %= Word.bitWidth
        } else {
            assert(head.remnantCount == 0)
        }

        // Prepend the whole words from the head.
        bits.insert(contentsOf: head.bits.prefix(head.wholeWordCount), at: bits.startIndex)
    }

    /**
     Returns a new instance with the suffix of the receiver.

     - Precondition: `0 <= bitCount <= count`.

     - Parameter bitCount: The number of bits copied from the end of `self`.

     - Returns: `BitArray(self.suffix(bitCount))`.
     */
    func tail(bitCount: Int) -> BitArray {
        let count = wholeWordCount * Word.bitWidth + remnantCount
        var copy = self
        copy.truncateHead(bitCount: count - bitCount)
        return copy
    }
    /**
     Removes the given number of elements from the end of the receiver.

     - Precondition: `0 <= bitCount <= count`.

     - Parameter bitCount: The number of bits removed from the end of `self`.

     - Postcondition: Same as `self.removeLast(bitCount)`.
     */
    mutating func truncateTail(bitCount: Int) {
        let count = wholeWordCount * Word.bitWidth + remnantCount
        precondition(0...count ~= bitCount)

        let headCount = count - bitCount
        let (hq, hr) = headCount.quotientAndRemainder(dividingBy: Word.bitWidth)
        var truncationIndex = bits.index(bits.startIndex, offsetBy: hq)
        if hr != 0 {
            assert(truncationIndex < bits.endIndex)
            bits[truncationIndex] &= Word.highOrderBitsMask(count: hr)
            truncationIndex = bits.index(after: truncationIndex)
        }
        bits.removeSubrange(truncationIndex...)
        remnantCount = hr
    }
    /**
     Inserts the elements of `tail` to the end of the receiver.

     - Parameter tail: The source of the new elements.

     - Postcondition:
        - `count == oldSelf.count + tail.count`.
        - `self.prefix(oldSelf.count) == oldSelf`.
        - `self.suffix(tail.count) == tail`.
     */
    mutating func appendTail(_ tail: BitArray) {
        var copy = tail
        copy.prependHead(self)
        bits.replaceSubrange(bits.startIndex..., with: copy.bits)  // Should preserve capacity.
        remnantCount = copy.remnantCount
    }

}
