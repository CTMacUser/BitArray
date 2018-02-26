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
     Creates an instance whose bits are sourced from the given sequence of an exact type of word.

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

// MARK: Word-Exploding Initialization

extension BitArray {

    /**
     Creates an instance whose bits are sourced from the given word.

     - Precondition: `0 <= bitCount <= word.bitWidth`.

     - Parameter word: The source of the stored bits.
     - Parameter bitCount: The number of bits to store.  After this many bits have been read from `word` for their Boolean values, the remainder are ignored.
     - Parameter bitIterationDirection: Whether the high-order bits of `word` are the ones that should be read first, proceeding towards the low-order bits, or vice versa.

     - Postcondition:
        - `count == bitCount`.
        - if *s* is a `Sequence` that vends the exploded bits of `word` (in `bitIterationDirection` order), then `s.prefix(bitCount).elementsEqual(self)`.
     */
    public init<W: UnsignedInteger>(word: W, bitCount: Int, bitIterationDirection: EndianTraversal) {
        precondition(0...word.bitWidth ~= bitCount)

        let coreWords: WordArray
        switch bitIterationDirection {
        case .lo2hi:
            coreWords = WordArray(word.words)
        case .hi2lo:
            let (wbwq, wbwr) = word.bitWidth.quotientAndRemainder(dividingBy: Word.bitWidth)
            let wordWords = WordArray(word.words)
            assert(wbwq + wbwr.signum() == wordWords.count)
            let highOrderWordBitCount = wbwr != 0 ? wbwr : wbwq.signum() * Word.bitWidth
            let head = BitArray(coreWords: [wordWords.last! << (Word.bitWidth - highOrderWordBitCount)], bitCount: highOrderWordBitCount, bitIterationDirection: .hi2lo)
            var tail = BitArray(coreWords: wordWords.dropLast().reversed(), bitCount: Word.bitWidth * (wordWords.count - 1), bitIterationDirection: .hi2lo)
            tail.prependHead(head)
            coreWords = tail.bits
        }
        self.init(coreWords: coreWords, bitCount: bitCount, bitIterationDirection: bitIterationDirection)
    }

    /**
     Creates an instance whose bits are sourced from the given sequence of words.

     If `bitCount` is not divided by `S.Element.bitWidth` evenly, then only some of the bits of the last non-ignored word are used.  Whether the most- or least-significant bits of that last word are counted depends on `bitIterationDirection`.

     - Precondition: `0 <= bitCount <= words.map { $0.bitWidth }.reduce(0, +)`.

     - Parameter words: The sequence of words that are the source of the stored bits.  The bits from a given word are mapped to being earlier in this sequence than the bits from any later word.
     - Parameter bitCount: The number of bits to store.  After enough bits have been read from elements of `words`, the remaining bits of the last scanned word (if any), and the entirety of all subsequent words, are ignored.
     - Parameter bitIterationDirection: Whether within a word the high-order bits are scanned first for this sequence, proceeding towards the low-order bits, or vice versa.  If the last word scanned is done partially, the bits with orders at the far end of the given direction are ignored.

     - Postcondition:
        - `count == bitCount`.
        - If *s* is a `Sequence` that vends the exploded bits from the elements of `words` (in `bitIterationDirection` order), then `s.elementsEqual(self)`.
     */
    public init<S>(words: S, bitCount: Int, bitIterationDirection: EndianTraversal) where S: Sequence, S.Element: UnsignedInteger {
        let bitArraySlivers = words.map { BitArray(word: $0, bitCount: $0.bitWidth, bitIterationDirection: bitIterationDirection) }
        var scratch = BitArray(coreWords: [], bitCount: 0, bitIterationDirection: bitIterationDirection)
        for s in bitArraySlivers.reversed() {
            scratch.prependHead(s)
        }
        self = scratch.head(bitCount: bitCount)
    }

}

// MARK: Diagnostic Output

extension BitArray: CustomDebugStringConvertible {

    public var debugDescription: String {
        // Sneak in an invariant check.
        precondition(0..<Word.bitWidth ~= remnantCount)  // Remnant count in range
        precondition(!bits.isEmpty || remnantCount == 0)  // Remant count set correctly when remnant doesn't exist
        precondition(remnantCount == 0 || (bits[remnantWordIndex!] << remnantCount == 0))  // Unused bits in remnant are unset

        // Print all the bits of each fully used word.
        var bitsStrings = bits.prefix(wholeWordCount).map { $0.fullHexadecimalString }

        // If the last word is partially used, list how many of its bits are used.
        if let remnantIndex = remnantWordIndex {
            let (rq, rr) = remnantCount.quotientAndRemainder(dividingBy: 4)
            let remnantHexDigitCount = rq + rr.signum()
            let remnantShortWordValue = bits[remnantIndex] >> (Word.bitWidth - remnantCount)
            let remnantDisplayString = String(remnantShortWordValue, radix: 16, uppercase: true).paddingPrepended("0", totalCount: remnantHexDigitCount) + " (\(remnantCount))"
            bitsStrings.append(remnantDisplayString)
        }

        // Comma-separate each word during display.
        return "BitArray([\(bitsStrings.joined(separator: ", "))])"
    }

}

// MARK: Collection Interfaces

/// A location of a specific `Bool` element within a `BitArray`.
public struct BitArrayIndex {

    /// The location of the word containing the targeted element.
    let index: BitArray.WordArray.Index
    /// The mask for the targeted element within its word.
    let mask: BitArray.Word

}

extension BitArrayIndex: Equatable {

    public static func ==(lhs: BitArrayIndex, rhs: BitArrayIndex) -> Bool {
        return lhs.index == rhs.index && lhs.mask == rhs.mask
    }

}

extension BitArrayIndex: Comparable {

    public static func <(lhs: BitArrayIndex, rhs: BitArrayIndex) -> Bool {
        return lhs.index < rhs.index || lhs.index == rhs.index && lhs.mask > rhs.mask
    }

}

extension BitArray: MutableCollection, RandomAccessCollection, RangeReplaceableCollection {

    public var startIndex: BitArrayIndex {
        return BitArrayIndex(index: bits.startIndex, mask: Word.highestOrderBitMask)
    }

    public var endIndex: BitArrayIndex {
        return BitArrayIndex(index: bits.index(bits.endIndex, offsetBy: -remnantCount.signum()), mask: Word.highestOrderBitMask >> remnantCount)
    }

    public subscript(position: BitArrayIndex) -> Bool {
        get { return bits[position.index] & position.mask != 0 }
        set {
            if newValue {
                bits[position.index] |= position.mask
            } else {
                bits[position.index] &= ~position.mask
            }
        }
    }

    public func index(after i: BitArrayIndex) -> BitArrayIndex {
        guard i.mask > 1 else {
            return BitArrayIndex(index: bits.index(after: i.index), mask: Word.highestOrderBitMask)
        }

        return BitArrayIndex(index: i.index, mask: i.mask >> 1)
    }

    public func index(before i: BitArrayIndex) -> BitArrayIndex {
        guard i.mask < Word.highestOrderBitMask else {
            return BitArrayIndex(index: bits.index(before: i.index), mask: 1)
        }

        return BitArrayIndex(index: i.index, mask: i.mask << 1)
    }

    public func index(_ i: BitArrayIndex, offsetBy n: Int) -> BitArrayIndex {
        let (wordShift, bitShift) = n.quotientAndRemainder(dividingBy: Word.bitWidth)
        var newIndex = bits.index(i.index, offsetBy: wordShift)
        var newMaskOffset = i.mask.leadingZeroBitCount + bitShift
        assert(0...(2 * (Word.bitWidth - 1)) ~= abs(newMaskOffset))
        if newMaskOffset < 0 {
            newMaskOffset += Word.bitWidth
            bits.formIndex(before: &newIndex)
        } else if newMaskOffset >= Word.bitWidth {
            newMaskOffset -= Word.bitWidth
            bits.formIndex(after: &newIndex)
        }
        assert(0..<Word.bitWidth ~= newMaskOffset)
        return BitArrayIndex(index: newIndex, mask: Word.highestOrderBitMask >> newMaskOffset)
    }

    public func distance(from start: BitArrayIndex, to end: BitArrayIndex) -> Int {
        // Sneak in an invariant check.
        precondition(start.mask.nonzeroBitCount == 1)
        precondition(end.mask.nonzeroBitCount == 1)

        return bits.distance(from: start.index, to: end.index) * Word.bitWidth + (end.mask.leadingZeroBitCount - start.mask.leadingZeroBitCount)
    }

    public init<S>(_ elements: S) where S: Sequence, S.Element == Element {
        let (ucq, ucr) = elements.underestimatedCount.quotientAndRemainder(dividingBy: Word.bitWidth)
        var newBits = WordArray()
        newBits.reserveCapacity(ucq + ucr.signum())
        var elementCount = 0
        var mask = Word()
        var lastIndex = newBits.endIndex
        for element in elements {
            elementCount += 1
            if mask == 0 {
                mask = Word.highestOrderBitMask
                newBits.append(0)
                lastIndex = newBits.index(before: newBits.endIndex)
            }
            if element {
                newBits[lastIndex] |= mask
            }
            mask >>= 1
        }
        self.init(coreWords: newBits, bitCount: elementCount, bitIterationDirection: .hi2lo)
    }

    public init() {
        self.init(coreWords: EmptyCollection(), bitCount: 0, bitIterationDirection: .hi2lo)
    }

    public mutating func replaceSubrange<C>(_ subrange: Range<Index>, with newElements: C) where C: Collection, C.Element == Element {
        precondition(startIndex <= subrange.lowerBound)
        precondition(subrange.lowerBound <= subrange.upperBound)
        precondition(subrange.upperBound <= endIndex)

        // No change if nothing gets added and nothing gets removed.
        let newBits = BitArray(newElements)
        guard !newBits.bits.isEmpty || !subrange.isEmpty else { return }

        // Something has to change.
        switch (subrange.lowerBound, subrange.upperBound) {
        case (startIndex, endIndex):
            // Total replacement.
            bits.replaceSubrange(bits.startIndex..., with: newBits.bits)
            remnantCount = newBits.remnantCount
        case (startIndex, let e) where startIndex < e:
            // Truncate head.
            truncateHead(bitCount: distance(from: startIndex, to: e))
            fallthrough
        case (_, startIndex):
            // Prepend.
            prependHead(newBits)
        case (let s, endIndex) where s < endIndex:
            // Truncate tail.
            truncateTail(bitCount: distance(from: s, to: endIndex))
            fallthrough
        case (endIndex, _):
            // Append.
            appendTail(newBits)
        default:
            // Mid-collection insertion (empty subrange), removal (empty newBits), or swap-out (neither empty).
            let replacementHead = head(bitCount: distance(from: startIndex, to: subrange.lowerBound))
            truncateHead(bitCount: distance(from: startIndex, to: subrange.upperBound))
            prependHead(newBits)
            prependHead(replacementHead)
        }
    }

    // MARK: Optimizations

    public var isEmpty: Bool {
        // When there's no bits stored, no fully- nor partially-used words are stored, so "bits" is empty.
        return bits.isEmpty
    }

    public var count: Int {
        // Just tweak the calculations needed for "endIndex".
        return (bits.count - remnantCount.signum()) * Word.bitWidth + remnantCount
    }

    public init(repeating repeatedValue: Element, count: Int) {
        // All-1s or all-0s can be set in bulk with word-level ~0 and 0.
        let (wordCount, leftOverBitCount) = count.quotientAndRemainder(dividingBy: Word.bitWidth)
        let repeatedWordCount = wordCount + leftOverBitCount.signum()
        let repeatedWordValue = repeatedValue ? Word.max : Word.min
        self.init(coreWords: repeatElement(repeatedWordValue, count: repeatedWordCount), bitCount: count, bitIterationDirection: .hi2lo)
    }

    public mutating func append<S>(contentsOf newElements: S) where S: Sequence, S.Element == Element {
        // The default code tries to reserve space then repeatedly call the single-element version.  With the way newly-inserted values are created before storage, a bulk-add is a lot more efficient.
        appendTail(BitArray(newElements))
    }

}
