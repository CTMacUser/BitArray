/*

  BitArrayTests.swift
  BitArrayTests

  Created by Daryle Walker on 1/29/18.
  Copyright (c) 2018 Daryle Walker.
  Distributed under the MIT License.

 */

import XCTest
@testable import BitArray


class BitArrayTests: XCTestCase {

    // An unsigned integer type bigger than any of the standard ones.
    struct UInt72: FixedWidthInteger, UnsignedInteger {
        // Implementation properties
        var high: UInt8
        var low: UInt64

        // Main initializer
        init(highOrderBits hi: UInt8, lowOrderBits lo: UInt64) { (high, low) = (hi, lo) }

        // FixedWidthInteger secret initializer
        init(_truncatingBits bits: UInt) { self.init(highOrderBits: 0, lowOrderBits: UInt64(bits)) }

        // FixedWidthInteger properties
        var byteSwapped: UInt72 {
            return UInt72(highOrderBits: UInt8(truncatingIfNeeded: low), lowOrderBits: (low.byteSwapped << 8) | UInt64(high))
        }
        var leadingZeroBitCount: Int { return high != 0 ? high.leadingZeroBitCount : 8 + low.leadingZeroBitCount }
        var nonzeroBitCount: Int { return high.nonzeroBitCount + low.nonzeroBitCount }

        static var bitWidth: Int { return 72 }

        // BinaryInteger properties
        var trailingZeroBitCount: Int { return low != 0 ? low.trailingZeroBitCount : high.trailingZeroBitCount + 64 }
        var words: [UInt] { return Array(low.words) + high.words }

        // ExpressibleByIntegerLiteral and Hashable support
        init(integerLiteral value: UInt) { self.init(_truncatingBits: value) }

        var hashValue: Int { return String(describing: self).hashValue }

        // BinaryInteger floating-point initializer
        init<T>(_ source: T) where T : BinaryFloatingPoint { fatalError("\(#function) not implemented") }

        // FixedWidthInteger core math
        func addingReportingOverflow(_ rhs: UInt72) -> (partialValue: UInt72, overflow: Bool) {
            fatalError("\(#function) not implemented")
        }
        func dividedReportingOverflow(by rhs: UInt72) -> (partialValue: UInt72, overflow: Bool) {
            fatalError("\(#function) not implemented")
        }
        func dividingFullWidth(_ dividend: (high: UInt72, low: UInt72)) -> (quotient: UInt72, remainder: UInt72) {
            fatalError("\(#function) not implemented")
        }
        func multipliedReportingOverflow(by rhs: UInt72) -> (partialValue: UInt72, overflow: Bool) {
            fatalError("\(#function) not implemented")
        }
        func multipliedFullWidth(by other: UInt72) -> (high: UInt72, low: UInt72) {
            fatalError("\(#function) not implemented")
        }
        func remainderReportingOverflow(dividingBy rhs: UInt72) -> (partialValue: UInt72, overflow: Bool) {
            fatalError("\(#function) not implemented")
        }
        func subtractingReportingOverflow(_ rhs: UInt72) -> (partialValue: UInt72, overflow: Bool) {
            fatalError("\(#function) not implemented")
        }

        // BinaryInteger operators
        static prefix func ~(x: UInt72) -> UInt72 { return UInt72(highOrderBits: ~x.high, lowOrderBits: ~x.low) }

        static func &=(lhs: inout UInt72, rhs: UInt72) { lhs.high &= rhs.high ; lhs.low &= rhs.low }
        static func ^=(lhs: inout UInt72, rhs: UInt72) { lhs.high ^= rhs.high ; lhs.low ^= rhs.low }
        static func |=(lhs: inout UInt72, rhs: UInt72) { lhs.high |= rhs.high ; lhs.low |= rhs.low }

        static func %(lhs: UInt72, rhs: UInt72) -> UInt72 {
            let results = lhs.remainderReportingOverflow(dividingBy: rhs)
            assert(!results.overflow)
            return results.partialValue
        }
        static func *(lhs: UInt72, rhs: UInt72) -> UInt72 {
            let results = lhs.multipliedReportingOverflow(by: rhs)
            assert(!results.overflow)
            return results.partialValue
        }
        static func +(lhs: UInt72, rhs: UInt72) -> UInt72 {
            let results = lhs.addingReportingOverflow(rhs)
            assert(!results.overflow)
            return results.partialValue
        }
        static func -(lhs: UInt72, rhs: UInt72) -> UInt72 {
            let results = lhs.subtractingReportingOverflow(rhs)
            assert(!results.overflow)
            return results.partialValue
        }
        static func /(lhs: UInt72, rhs: UInt72) -> UInt72 {
            let results = lhs.dividedReportingOverflow(by: rhs)
            assert(!results.overflow)
            return results.partialValue
        }

        static func %=(lhs: inout UInt72, rhs: UInt72) { lhs = lhs % rhs }
        static func *=(lhs: inout UInt72, rhs: UInt72) { lhs = lhs * rhs }
        static func +=(lhs: inout UInt72, rhs: UInt72) { lhs = lhs + rhs }
        static func -=(lhs: inout UInt72, rhs: UInt72) { lhs = lhs - rhs }
        static func /=(lhs: inout UInt72, rhs: UInt72) { lhs = lhs / rhs }
    }

    // Test the original initializer.
    func testPrimaryInitializer() {
        // No words.
        let subject1 = BitArray(coreWords: [], bitCount: 0, bitIterationDirection: .hi2lo)
        let subject2 = BitArray(coreWords: [], bitCount: 0, bitIterationDirection: .lo2hi)
        XCTAssertEqual(subject1.bits, [])
        XCTAssertEqual(subject1.remnantCount, 0)
        XCTAssertEqual(subject2.bits, [])
        XCTAssertEqual(subject2.remnantCount, 0)

        // Don't need words.
        let fSample32: UInt32 = 0x01010101
        let rSample32: UInt32 = 0x80808080
        let fSample: UInt = UInt(fSample32) << 32 | UInt(fSample32)
        let rSample: UInt = UInt(rSample32) << 32 | UInt(rSample32)
        let subject3 = BitArray(coreWords: [fSample, fSample], bitCount: 0, bitIterationDirection: .hi2lo)
        let subject4 = BitArray(coreWords: [rSample], bitCount: 0, bitIterationDirection: .lo2hi)
        XCTAssertEqual(subject3.bits, [])
        XCTAssertEqual(subject3.remnantCount, 0)
        XCTAssertEqual(subject4.bits, [])
        XCTAssertEqual(subject4.remnantCount, 0)

        // Exact word, either endian.
        let subject5 = BitArray(coreWords: [fSample], bitCount: UInt.bitWidth, bitIterationDirection: .hi2lo)
        let subject6 = BitArray(coreWords: [rSample], bitCount: UInt.bitWidth, bitIterationDirection: .lo2hi)
        XCTAssertEqual(subject5.bits, [fSample])
        XCTAssertEqual(subject5.remnantCount, 0)
        XCTAssertEqual(subject6.bits, [fSample])
        XCTAssertEqual(subject6.remnantCount, 0)

        // Short word.
        let subject7 = BitArray(coreWords: [fSample], bitCount: 10, bitIterationDirection: .hi2lo)
        let subject8 = BitArray(coreWords: [rSample], bitCount: 10, bitIterationDirection: .lo2hi)
        XCTAssertEqual(subject7.bits, [(0x004 as UInt) << (UInt.bitWidth - 10)])
        XCTAssertEqual(subject7.remnantCount, 10)
        XCTAssertEqual(subject8.bits, [(0x004 as UInt) << (UInt.bitWidth - 10)])
        XCTAssertEqual(subject8.remnantCount, 10)

        // Multiple words, short end.
        let fdSample32: UInt32 = 0x0F0F0F0F
        let rdSample32: UInt32 = 0xF0F0F0F0
        let fdSample: UInt = UInt(fdSample32) << 32 | UInt(fdSample32)
        let rdSample: UInt = UInt(rdSample32) << 32 | UInt(rdSample32)
        let subject9 = BitArray(coreWords: [rSample, fSample, fdSample, rdSample], bitCount: 2 * UInt.bitWidth + 6, bitIterationDirection: .hi2lo)
        let subject10 = BitArray(coreWords: [fSample, rSample, rdSample, fdSample], bitCount: 2 * UInt.bitWidth + 6, bitIterationDirection: .lo2hi)
        XCTAssertEqual(subject9.bits, [rSample, fSample, (0x03 as UInt) << (UInt.bitWidth - 6)])
        XCTAssertEqual(subject9.remnantCount, 6)
        XCTAssertEqual(subject10.bits, [rSample, fSample, (0x03 as UInt) << (UInt.bitWidth - 6)])
        XCTAssertEqual(subject10.remnantCount, 6)
    }

    // Test tracking the word holding any remnant bits.
    func testRemnantTracking() {
        // No words.
        let subject1 = BitArray(coreWords: [], bitCount: 0, bitIterationDirection: .hi2lo)
        XCTAssertNil(subject1.remnantWordIndex)
        XCTAssertEqual(subject1.wholeWordCount, 0)

        // Partially used word.
        let subject2 = BitArray(coreWords: [UInt.max], bitCount: 17, bitIterationDirection: .lo2hi)
        XCTAssertEqual(subject2.remnantWordIndex, subject2.bits.index(before: subject2.bits.endIndex))
        XCTAssertEqual(subject2.wholeWordCount, 0)

        // Exactly one word.
        let subject3 = BitArray(coreWords: [UInt.max], bitCount: UInt.bitWidth, bitIterationDirection: .hi2lo)
        XCTAssertNil(subject3.remnantWordIndex)
        XCTAssertEqual(subject3.wholeWordCount, 1)

        // Full and partial words.
        let subject4 = BitArray(coreWords: [UInt.min, UInt.max, 0xABCD], bitCount: 13 + 2 * UInt.bitWidth, bitIterationDirection: .lo2hi)
        XCTAssertEqual(subject4.remnantWordIndex, subject4.bits.index(before: subject4.bits.endIndex))
        XCTAssertEqual(subject4.wholeWordCount, 2)
    }

    // Test inspecting the head of an array.
    func testHeadExtraction() {
        // No words.
        let subject1 = BitArray(coreWords: [], bitCount: 0, bitIterationDirection: .hi2lo)
        let subject1Head = subject1.head(bitCount: 0)
        XCTAssertEqual(subject1Head.bits, [])
        XCTAssertEqual(subject1Head.remnantCount, 0)

        let subject2 = BitArray(coreWords: repeatElement(UInt.max - 1, count: 3), bitCount: 2 * UInt.bitWidth + 20, bitIterationDirection: .lo2hi)
        let subject2EmptyHead = subject2.head(bitCount: 0)
        XCTAssertEqual(subject2EmptyHead.bits, [])
        XCTAssertEqual(subject2EmptyHead.remnantCount, 0)

        // Part of first word.
        let subject2HalfWordHead = subject2.head(bitCount: UInt.bitWidth / 2)
        XCTAssertEqual(subject2HalfWordHead.bits, [UInt.highOrderBitsMask(count: UInt.bitWidth / 2 - 1) >> 1])
        XCTAssertEqual(subject2HalfWordHead.remnantCount, UInt.bitWidth / 2)

        // A complete word.
        let subject2WordHead = subject2.head(bitCount: UInt.bitWidth)
        XCTAssertEqual(subject2WordHead.bits, [UInt.max >> 1])
        XCTAssertEqual(subject2WordHead.remnantCount, 0)

        // Full and partial words.
        let subject2MultiHead = subject2.head(bitCount: UInt.bitWidth + 2)
        XCTAssertEqual(subject2MultiHead.bits, [UInt.max >> 1, (0x01 as UInt) << (UInt.bitWidth - 2)])
        XCTAssertEqual(subject2MultiHead.remnantCount, 2)
    }

    // Test removal of the head of an array.
    func testHeadRemoval() {
        // No words.
        var subject1 = BitArray(coreWords: [], bitCount: 0, bitIterationDirection: .hi2lo)
        subject1.truncateHead(bitCount: 0)
        XCTAssertEqual(subject1.bits, [])
        XCTAssertEqual(subject1.remnantCount, 0)

        // Part of a partial word.
        let fSample32: UInt32 = 0xFEDCBA98
        let fSample: UInt = UInt(fSample32) << 32 | UInt(fSample32)
        subject1 = BitArray(coreWords: [fSample], bitCount: 24, bitIterationDirection: .hi2lo)
        XCTAssertEqual(subject1.bits, [(0xFEDCBA as UInt) << (UInt.bitWidth - 24)])
        XCTAssertEqual(subject1.remnantCount, 24)
        subject1.truncateHead(bitCount: 10)
        XCTAssertEqual(subject1.bits, [(0x1CBA as UInt) << (UInt.bitWidth - 14)])
        XCTAssertEqual(subject1.remnantCount, 14)

        // All of a partial word.
        subject1.truncateHead(bitCount: 14)
        XCTAssertEqual(subject1.bits, [])
        XCTAssertEqual(subject1.remnantCount, 0)

        // All of a sole word.
        subject1 = BitArray(coreWords: [fSample], bitCount: UInt.bitWidth, bitIterationDirection: .hi2lo)
        XCTAssertEqual(subject1.bits, [fSample])
        XCTAssertEqual(subject1.remnantCount, 0)
        subject1.truncateHead(bitCount: UInt.bitWidth)
        XCTAssertEqual(subject1.bits, [])
        XCTAssertEqual(subject1.remnantCount, 0)

        // Part of a sole word.
        subject1 = BitArray(coreWords: [fSample], bitCount: UInt.bitWidth, bitIterationDirection: .hi2lo)
        XCTAssertEqual(subject1.bits, [fSample])
        XCTAssertEqual(subject1.remnantCount, 0)
        subject1.truncateHead(bitCount: 14)
        XCTAssertEqual(subject1.bits, [fSample << 14])
        XCTAssertEqual(subject1.remnantCount, UInt.bitWidth - 14)

        // Whole word out of two.
        let rSample32: UInt32 = 0x80808080
        let rSample: UInt = UInt(rSample32) << 32 | UInt(rSample32)
        subject1 = BitArray(coreWords: [fSample, rSample], bitCount: 2 * UInt.bitWidth, bitIterationDirection: .hi2lo)
        XCTAssertEqual(subject1.bits, [fSample, rSample])
        XCTAssertEqual(subject1.remnantCount, 0)
        subject1.truncateHead(bitCount: UInt.bitWidth)
        XCTAssertEqual(subject1.bits, [rSample])
        XCTAssertEqual(subject1.remnantCount, 0)

        // Part of a word out of two whole words.
        subject1 = BitArray(coreWords: [fSample, rSample], bitCount: 2 * UInt.bitWidth, bitIterationDirection: .hi2lo)
        XCTAssertEqual(subject1.bits, [fSample, rSample])
        XCTAssertEqual(subject1.remnantCount, 0)
        subject1.truncateHead(bitCount: 8)
        XCTAssertEqual(subject1.bits, [(fSample << 8) | (rSample >> (UInt.bitWidth - 8)), rSample << 8])
        XCTAssertEqual(subject1.remnantCount, UInt.bitWidth - 8)

        // One and a part words out of three whole words
        subject1 = BitArray(coreWords: [rSample, fSample, rSample], bitCount: 3 * UInt.bitWidth, bitIterationDirection: .hi2lo)
        XCTAssertEqual(subject1.bits, [rSample, fSample, rSample])
        XCTAssertEqual(subject1.remnantCount, 0)
        subject1.truncateHead(bitCount: UInt.bitWidth + 8)
        XCTAssertEqual(subject1.bits, [(fSample << 8) | (rSample >> (UInt.bitWidth - 8)), rSample << 8])
        XCTAssertEqual(subject1.remnantCount, UInt.bitWidth - 8)

        // Part of a word out of one and a part words, no word count reduction.
        subject1 = BitArray(coreWords: [fSample, rSample], bitCount: UInt.bitWidth + 16, bitIterationDirection: .hi2lo)
        XCTAssertEqual(subject1.bits, [fSample, UInt(0x8080) << (UInt.bitWidth - 16)])
        XCTAssertEqual(subject1.remnantCount, 16)
        subject1.truncateHead(bitCount: 8)
        let expressionTooComplexA: UInt = 0x80
        let expressionTooComplexB: UInt = (fSample << 8) | expressionTooComplexA
        let expressionTooComplexC: UInt = expressionTooComplexA << (UInt.bitWidth - 8)
        XCTAssertEqual(subject1.bits, [expressionTooComplexB, expressionTooComplexC])
        XCTAssertEqual(subject1.remnantCount, 8)

        // Part of a word out of one and a part words, with word count reduction.
        subject1 = BitArray(coreWords: [fSample, rSample], bitCount: UInt.bitWidth + 16, bitIterationDirection: .hi2lo)
        subject1.truncateHead(bitCount: 24)
        XCTAssertEqual(subject1.bits, [(fSample << 24) | (UInt(0x8080) << 8)])
        XCTAssertEqual(subject1.remnantCount, UInt.bitWidth - 8)
    }

    // Test inserting a new head for an array.
    func testHeadInsertion() {
        // Empty source and destination.
        let empty = BitArray(coreWords: [], bitCount: 0, bitIterationDirection: .hi2lo)
        var subject1 = empty
        XCTAssertEqual(subject1.bits, [])
        XCTAssertEqual(subject1.remnantCount, 0)
        subject1.prependHead(empty)
        XCTAssertEqual(subject1.bits, [])
        XCTAssertEqual(subject1.remnantCount, 0)

        // Empty source or destination, vs. single word array.
        let fdSample32: UInt32 = 0x0F0F0F0F
        let fdSample: UInt = UInt(fdSample32) << 32 | UInt(fdSample32)
        let singleSample = BitArray(coreWords: [fdSample], bitCount: UInt.bitWidth, bitIterationDirection: .hi2lo)
        subject1 = singleSample
        XCTAssertEqual(subject1.bits, [fdSample])
        XCTAssertEqual(subject1.remnantCount, 0)
        subject1.prependHead(empty)
        XCTAssertEqual(subject1.bits, [fdSample])
        XCTAssertEqual(subject1.remnantCount, 0)
        subject1 = empty
        XCTAssertEqual(subject1.bits, [])
        XCTAssertEqual(subject1.remnantCount, 0)
        subject1.prependHead(singleSample)
        XCTAssertEqual(subject1.bits, [fdSample])
        XCTAssertEqual(subject1.remnantCount, 0)

        // Pre-pend a head that fits exactly on a word boundary.
        subject1.prependHead(singleSample)
        XCTAssertEqual(subject1.bits, [fdSample, fdSample])
        XCTAssertEqual(subject1.remnantCount, 0)

        // Pre-pend a short head.
        let rdSample32: UInt32 = 0xF0F0F0F0
        let rdSample: UInt = UInt(rdSample32) << 32 | UInt(rdSample32)
        let octetSample = BitArray(coreWords: [rdSample], bitCount: 8, bitIterationDirection: .hi2lo)
        subject1.prependHead(octetSample)
        let expressionTooComplexA = (UInt(0xF0) << (UInt.bitWidth - 8)) | (fdSample >> 8)
        XCTAssertEqual(subject1.bits, [expressionTooComplexA, fdSample, UInt(0x0F) << (UInt.bitWidth - 8)])
        XCTAssertEqual(subject1.remnantCount, 8)

        // Pre-pend arrays, both with remnants, but don't complete a word.
        let wordAndOctetSample = BitArray(coreWords: [rdSample, rdSample], bitCount: UInt.bitWidth + 8, bitIterationDirection: .hi2lo)
        let expressionTooComplexB = (UInt(0xF0) << (UInt.bitWidth - 8)) | (expressionTooComplexA >> 8)
        subject1.prependHead(wordAndOctetSample)
        XCTAssertEqual(subject1.bits, [rdSample, expressionTooComplexB, fdSample, UInt(0x0F0F) << (UInt.bitWidth - 16)])
        XCTAssertEqual(subject1.remnantCount, 16)

        // Pre-pend enough bits to complete remnant to a word.
        let anotherSample = BitArray(coreWords: [fdSample, rdSample], bitCount: 2 * UInt.bitWidth - 16, bitIterationDirection: .hi2lo)
        subject1.prependHead(anotherSample)
        XCTAssertEqual(subject1.bits, [fdSample, rdSample,  rdSample, fdSample, fdSample])
        XCTAssertEqual(subject1.remnantCount, 0)
    }

    // Test inspecting the tail of an array.
    func testTailExtraction() {
        // No words
        let empty = BitArray(coreWords: [], bitCount: 0, bitIterationDirection: .hi2lo)
        var subject1 = empty.tail(bitCount: 0)
        XCTAssertEqual(subject1.bits, [])
        XCTAssertEqual(subject1.remnantCount, 0)

        let fdSample32: UInt32 = 0x0F0F0F0F
        let rdSample32: UInt32 = 0xF0F0F0F0
        let fdSample: UInt = UInt(fdSample32) << 32 | UInt(fdSample32)
        let rdSample: UInt = UInt(rdSample32) << 32 | UInt(rdSample32)
        let threeWords = BitArray(coreWords: [fdSample, rdSample, fdSample], bitCount: 3 * UInt.bitWidth, bitIterationDirection: .hi2lo)
        subject1 = threeWords.tail(bitCount: 0)
        XCTAssertEqual(subject1.bits, [])
        XCTAssertEqual(subject1.remnantCount, 0)

        // Partial word.
        subject1 = threeWords.tail(bitCount: 16)
        XCTAssertEqual(subject1.bits, [UInt(0x0F0F) << (UInt.bitWidth - 16)])
        XCTAssertEqual(subject1.remnantCount, 16)

        // Whole word.
        subject1 = threeWords.tail(bitCount: UInt.bitWidth)
        XCTAssertEqual(subject1.bits, [fdSample])
        XCTAssertEqual(subject1.remnantCount, 0)

        // Whole and partial word.
        subject1 = threeWords.tail(bitCount: UInt.bitWidth + 16)
        let whole = (rdSample << (UInt.bitWidth - 16)) | (fdSample >> 16)
        let part = UInt(0x0F0F) << (UInt.bitWidth - 16)
        XCTAssertEqual(subject1.bits, [whole, part])
        XCTAssertEqual(subject1.remnantCount, 16)

        // Everything.
        subject1 = threeWords.tail(bitCount: UInt.bitWidth * 3)
        XCTAssertEqual(subject1.bits, [fdSample, rdSample, fdSample])
        XCTAssertEqual(subject1.remnantCount, 0)
    }

    // Test removal of the tail of an array.
    func testTailRemoval() {
        // Empty.
        var subject1 = BitArray(coreWords: [], bitCount: 0, bitIterationDirection: .hi2lo)
        subject1.truncateTail(bitCount: 0)
        XCTAssertEqual(subject1.bits, [])
        XCTAssertEqual(subject1.remnantCount, 0)

        let fdSample32: UInt32 = 0x0F0F0F0F
        let rdSample32: UInt32 = 0xF0F0F0F0
        let fdSample: UInt = UInt(fdSample32) << 32 | UInt(fdSample32)
        let rdSample: UInt = UInt(rdSample32) << 32 | UInt(rdSample32)
        let threeWords = BitArray(coreWords: [fdSample, rdSample, fdSample], bitCount: 3 * UInt.bitWidth, bitIterationDirection: .hi2lo)
        subject1 = threeWords
        subject1.truncateTail(bitCount: 0)
        XCTAssertEqual(subject1.bits, [fdSample, rdSample, fdSample])
        XCTAssertEqual(subject1.remnantCount, 0)

        // Everything.
        subject1.truncateTail(bitCount: 3 * UInt.bitWidth)
        XCTAssertEqual(subject1.bits, [])
        XCTAssertEqual(subject1.remnantCount, 0)

        // Full word.
        subject1 = threeWords
        subject1.truncateTail(bitCount: UInt.bitWidth)
        XCTAssertEqual(subject1.bits, [fdSample, rdSample])
        XCTAssertEqual(subject1.remnantCount, 0)

        // Part word, from full words.
        subject1.truncateTail(bitCount: 16)
        XCTAssertEqual(subject1.bits, [fdSample, rdSample << 16])
        XCTAssertEqual(subject1.remnantCount, UInt.bitWidth - 16)

        // Part word, to part word.
        subject1.truncateTail(bitCount: 8)
        XCTAssertEqual(subject1.bits, [fdSample, rdSample << 24])
        XCTAssertEqual(subject1.remnantCount, UInt.bitWidth - 24)

        subject1.truncateTail(bitCount: UInt.bitWidth + 4)
        XCTAssertEqual(subject1.bits, [fdSample & ~UInt.lowOrderBitsMask(count: 28)])
        XCTAssertEqual(subject1.remnantCount, UInt.bitWidth - 28)
    }

    // Test inserting a new tail for an array.
    func testTailInsertion() {
        let fdSample32: UInt32 = 0x0F0F0F0F
        let rdSample32: UInt32 = 0xF0F0F0F0
        let fdSample: UInt = UInt(fdSample32) << 32 | UInt(fdSample32)
        let rdSample: UInt = UInt(rdSample32) << 32 | UInt(rdSample32)
        let fdArray = BitArray(coreWords: [fdSample], bitCount: UInt.bitWidth, bitIterationDirection: .hi2lo)
        let rdArray = BitArray(coreWords: [rdSample], bitCount: UInt.bitWidth, bitIterationDirection: .hi2lo)
        let empty = BitArray(coreWords: [], bitCount: 0, bitIterationDirection: .hi2lo)

        // Empty.
        var subject1 = empty
        subject1.appendTail(empty)
        XCTAssertEqual(subject1.bits, [])
        XCTAssertEqual(subject1.remnantCount, 0)

        subject1.appendTail(fdArray)
        XCTAssertEqual(subject1.bits, [fdSample])
        XCTAssertEqual(subject1.remnantCount, 0)

        subject1.appendTail(empty)
        XCTAssertEqual(subject1.bits, [fdSample])
        XCTAssertEqual(subject1.remnantCount, 0)

        // Word on word.
        subject1.appendTail(rdArray)
        XCTAssertEqual(subject1.bits, [fdSample, rdSample])
        XCTAssertEqual(subject1.remnantCount, 0)

        // Partial word on word.
        let fdPartial = BitArray(coreWords: [fdSample], bitCount: 16, bitIterationDirection: .hi2lo)
        subject1.appendTail(fdPartial)
        XCTAssertEqual(subject1.bits, [fdSample, rdSample, fdSample << (UInt.bitWidth - 16)])
        XCTAssertEqual(subject1.remnantCount, 16)

        // Partial on partial; same end word.
        let fdPartialOctet = BitArray(coreWords: [fdSample], bitCount: 8, bitIterationDirection: .hi2lo)
        subject1.appendTail(fdPartialOctet)
        XCTAssertEqual(subject1.bits, [fdSample, rdSample, fdSample << (UInt.bitWidth - 24)])
        XCTAssertEqual(subject1.remnantCount, 24)

        // Partial to full.
        let fdRemainder = BitArray(coreWords: [fdSample], bitCount: UInt.bitWidth - 24, bitIterationDirection: .hi2lo)
        subject1.appendTail(fdRemainder)
        XCTAssertEqual(subject1.bits, [fdSample, rdSample, fdSample])
        XCTAssertEqual(subject1.remnantCount, 0)

        // Partial on partial; new end word.
        subject1 = BitArray(coreWords: [fdSample], bitCount: UInt.bitWidth - 8, bitIterationDirection: .hi2lo)
        XCTAssertEqual(subject1.bits, [fdSample << 8])
        XCTAssertEqual(subject1.remnantCount, UInt.bitWidth - 8)
        subject1.appendTail(fdPartial)
        XCTAssertEqual(subject1.bits, [fdSample, fdSample << (UInt.bitWidth - 8)])
        XCTAssertEqual(subject1.remnantCount, 8)
    }

    // Test initialization from an unsigned integer's bits.
    func testWordInitialization() {
        // A byte.
        let octet: UInt8 = 0xA7
        var subject1 = BitArray(word: octet, bitCount: 8, bitIterationDirection: .hi2lo)
        XCTAssertEqual(subject1.bits, [UInt(0xA7) << (UInt.bitWidth - 8)])
        XCTAssertEqual(subject1.remnantCount, 8)
        subject1 = BitArray(word: octet, bitCount: 8, bitIterationDirection: .lo2hi)
        XCTAssertEqual(subject1.bits, [UInt(0xE5) << (UInt.bitWidth - 8)])
        XCTAssertEqual(subject1.remnantCount, 8)

        // Part of a byte.
        subject1 = BitArray(word: octet, bitCount: 3, bitIterationDirection: .hi2lo)
        XCTAssertEqual(subject1.bits, [UInt(5) << (UInt.bitWidth - 3)])
        XCTAssertEqual(subject1.remnantCount, 3)
        subject1 = BitArray(word: octet, bitCount: 3, bitIterationDirection: .lo2hi)
        XCTAssertEqual(subject1.bits, [UInt(7) << (UInt.bitWidth - 3)])
        XCTAssertEqual(subject1.remnantCount, 3)

        // A word.
        let fdSample32: UInt32 = 0x0F0F0F0F
        let rdSample32: UInt32 = 0xF0F0F0F0
        let fdSample: UInt = UInt(fdSample32) << 32 | UInt(fdSample32)
        let rdSample: UInt = UInt(rdSample32) << 32 | UInt(rdSample32)
        subject1 = BitArray(word: fdSample, bitCount: UInt.bitWidth, bitIterationDirection: .hi2lo)
        XCTAssertEqual(subject1.bits, [fdSample])
        XCTAssertEqual(subject1.remnantCount, 0)
        subject1 = BitArray(word: fdSample, bitCount: UInt.bitWidth, bitIterationDirection: .lo2hi)
        XCTAssertEqual(subject1.bits, [rdSample])
        XCTAssertEqual(subject1.remnantCount, 0)

        // Part of a word.
        subject1 = BitArray(word: fdSample, bitCount: 16, bitIterationDirection: .hi2lo)
        XCTAssertEqual(subject1.bits, [fdSample << (UInt.bitWidth - 16)])
        XCTAssertEqual(subject1.remnantCount, 16)
        subject1 = BitArray(word: fdSample, bitCount: 16, bitIterationDirection: .lo2hi)
        XCTAssertEqual(subject1.bits, [rdSample << (UInt.bitWidth - 16)])
        XCTAssertEqual(subject1.remnantCount, 16)

        // Over a word.
        let longword = UInt72(highOrderBits: 0xAA, lowOrderBits: 0xEEEEEEEEEEEEEEEE)
        subject1 = BitArray(word: longword, bitCount: 72, bitIterationDirection: .hi2lo)
        let longLow = UInt(truncatingIfNeeded: longword.low)
        let longHigh = (UInt(longword.high) << (UInt.bitWidth - 8)) | (longLow >> 8)
        XCTAssertEqual(subject1.bits.first, longHigh)
        XCTAssertEqual(subject1.bits.last, longLow << (UInt.bitWidth - 8))
        XCTAssertEqual(subject1.bits.count, 72 / UInt.bitWidth + 1)
        XCTAssertEqual(subject1.remnantCount, 8)
        subject1 = BitArray(word: longword, bitCount: 72, bitIterationDirection: .lo2hi)
        let longLowR = UInt(truncatingIfNeeded: UInt64(0x7777777777777777))
        let longLowH = (longLowR << 8) | UInt(UInt64(0x55))
        XCTAssertEqual(subject1.bits.first, longLowR)
        XCTAssertEqual(subject1.bits.last, longLowH << (UInt.bitWidth - 8))
        XCTAssertEqual(subject1.bits.count, 72 / UInt.bitWidth + 1)
        XCTAssertEqual(subject1.remnantCount, 8)
    }

    // Test initialization from the bits from a sequence of unsigned integers.
    func testWordSequenceInitialization() {
        // Three bytes.
        let sample1: [UInt8] = [0xEE, 0xAA, 0x33]
        var subject1 = BitArray(words: sample1, bitCount: 24, bitIterationDirection: .hi2lo)
        XCTAssertEqual(subject1.bits, [UInt(0xEEAA33) << (UInt.bitWidth - 24)])
        XCTAssertEqual(subject1.remnantCount, 24)

        // Reverse bit-reading.
        subject1 = BitArray(words: sample1, bitCount: 24, bitIterationDirection: .lo2hi)
        XCTAssertEqual(subject1.bits, [UInt(0x7755CC) << (UInt.bitWidth - 24)])
        XCTAssertEqual(subject1.remnantCount, 24)

        // Partial.
        subject1 = BitArray(words: sample1, bitCount: 12, bitIterationDirection: .hi2lo)
        XCTAssertEqual(subject1.bits, [UInt(0xEEA) << (UInt.bitWidth - 12)])
        XCTAssertEqual(subject1.remnantCount, 12)
        subject1 = BitArray(words: sample1, bitCount: 12, bitIterationDirection: .lo2hi)
        XCTAssertEqual(subject1.bits, [UInt(0x775) << (UInt.bitWidth - 12)])
        XCTAssertEqual(subject1.remnantCount, 12)

        // Empty.
        subject1 = BitArray(words: [] as [UInt72], bitCount: 0, bitIterationDirection: .lo2hi)
        XCTAssertEqual(subject1.bits, [])
        XCTAssertEqual(subject1.remnantCount, 0)
    }

    // Test printing of debugging data.
    func testDebugPrinting() {
        // Empty.
        var subject1 = BitArray(coreWords: [], bitCount: 0, bitIterationDirection: .hi2lo)
        XCTAssertEqual(String(reflecting: subject1), "BitArray([])")

        // Single bit.
        subject1 = BitArray(word: 0 as UInt8, bitCount: 1, bitIterationDirection: .hi2lo)
        XCTAssertEqual(String(reflecting: subject1), "BitArray([0 (1)])")
        subject1 = BitArray(word: 0 as UInt8, bitCount: 1, bitIterationDirection: .lo2hi)
        XCTAssertEqual(String(reflecting: subject1), "BitArray([0 (1)])")
        subject1 = BitArray(word: (1 as UInt8) << 7, bitCount: 1, bitIterationDirection: .hi2lo)
        XCTAssertEqual(String(reflecting: subject1), "BitArray([1 (1)])")
        subject1 = BitArray(word: 1 as UInt8, bitCount: 1, bitIterationDirection: .lo2hi)
        XCTAssertEqual(String(reflecting: subject1), "BitArray([1 (1)])")

        // Sub-byte.
        subject1 = BitArray(word: 0x5E as UInt8, bitCount: 6, bitIterationDirection: .hi2lo)
        XCTAssertEqual(String(reflecting: subject1), "BitArray([17 (6)])")
        subject1 = BitArray(word: 0x5E as UInt8, bitCount: 6, bitIterationDirection: .lo2hi)
        XCTAssertEqual(String(reflecting: subject1), "BitArray([1E (6)])")

        // Sub-word.
        subject1 = BitArray(word: 0xAE91 as UInt16, bitCount: 16, bitIterationDirection: .hi2lo)
        XCTAssertEqual(String(reflecting: subject1), "BitArray([AE91 (16)])")
        subject1 = BitArray(word: 0xAE91 as UInt16, bitCount: 16, bitIterationDirection: .lo2hi)
        XCTAssertEqual(String(reflecting: subject1), "BitArray([8975 (16)])")

        // A word.
        let fdSample32: UInt32 = 0x0F0F0F0F
        let fdSample: UInt = UInt(fdSample32) << 32 | UInt(fdSample32)
        subject1 = BitArray(word: fdSample, bitCount: UInt.bitWidth, bitIterationDirection: .hi2lo)
        XCTAssertEqual(String(reflecting: subject1), "BitArray([\(fdSample.fullHexadecimalString)])")
        let rdSample32: UInt32 = 0xF0F0F0F0
        let rdSample: UInt = UInt(rdSample32) << 32 | UInt(rdSample32)
        subject1 = BitArray(word: fdSample, bitCount: UInt.bitWidth, bitIterationDirection: .lo2hi)
        XCTAssertEqual(String(reflecting: subject1), "BitArray([\(rdSample.fullHexadecimalString)])")

        // A word and a partial.
        subject1 = BitArray(coreWords: [fdSample, fdSample], bitCount: UInt.bitWidth + 8, bitIterationDirection: .hi2lo)
        XCTAssertEqual(String(reflecting: subject1), "BitArray([\(fdSample.fullHexadecimalString), 0F (8)])")
        subject1 = BitArray(coreWords: [fdSample, fdSample], bitCount: UInt.bitWidth + 8, bitIterationDirection: .lo2hi)
        XCTAssertEqual(String(reflecting: subject1), "BitArray([\(rdSample.fullHexadecimalString), F0 (8)])")

        // Multiple words.
        subject1 = BitArray(coreWords: [fdSample, rdSample], bitCount: 2 * UInt.bitWidth, bitIterationDirection: .hi2lo)
        XCTAssertEqual(String(reflecting: subject1), "BitArray([\(fdSample.fullHexadecimalString), \(rdSample.fullHexadecimalString)])")
        subject1 = BitArray(coreWords: [fdSample, rdSample], bitCount: 2 * UInt.bitWidth, bitIterationDirection: .lo2hi)
        XCTAssertEqual(String(reflecting: subject1), "BitArray([\(rdSample.fullHexadecimalString), \(fdSample.fullHexadecimalString)])")

        // Multiple words and a partial.
        subject1 = BitArray(coreWords: [fdSample, rdSample, 0x5E], bitCount: 2 * UInt.bitWidth + 6, bitIterationDirection: .hi2lo)
        XCTAssertEqual(String(reflecting: subject1), "BitArray([\(fdSample.fullHexadecimalString), \(rdSample.fullHexadecimalString), 00 (6)])")  // The set bits are too low-order to read!
        subject1 = BitArray(coreWords: [fdSample, rdSample, 0x5E], bitCount: 2 * UInt.bitWidth + 6, bitIterationDirection: .lo2hi)
        XCTAssertEqual(String(reflecting: subject1), "BitArray([\(rdSample.fullHexadecimalString), \(fdSample.fullHexadecimalString), 1E (6)])")
    }

    // Test comparison and forward traversal of indices.
    func testIndexComparisonAndForwardTraversal() {
        // Empty.
        var subject1 = BitArray(coreWords: [], bitCount: 0, bitIterationDirection: .hi2lo)
        XCTAssertEqual(subject1.startIndex.index, subject1.bits.startIndex)
        XCTAssertEqual(subject1.startIndex.mask, UInt.highestOrderBitMask)
        XCTAssertEqual(subject1.startIndex, subject1.endIndex)
        XCTAssertFalse(subject1.startIndex < subject1.endIndex)

        // Partial word.
        subject1 = BitArray(word: UInt.max, bitCount: 1, bitIterationDirection: .hi2lo)
        XCTAssertNotEqual(subject1.startIndex, subject1.endIndex)
        XCTAssertEqual(subject1.endIndex.index, subject1.bits.startIndex)
        XCTAssertEqual(subject1.endIndex.mask, UInt.highestOrderBitMask >> 1)
        XCTAssertLessThan(subject1.startIndex, subject1.endIndex)

        XCTAssertEqual(subject1.index(after: subject1.startIndex), subject1.endIndex)

        // Full word.
        subject1 = BitArray(word: UInt.min, bitCount: UInt.bitWidth, bitIterationDirection: .lo2hi)
        XCTAssertNotEqual(subject1.startIndex, subject1.endIndex)
        XCTAssertEqual(subject1.bits.index(after: subject1.startIndex.index), subject1.endIndex.index)
        XCTAssertEqual(subject1.endIndex.mask, UInt.highestOrderBitMask)
        XCTAssertEqual(subject1.endIndex.index, subject1.bits.endIndex)
        XCTAssertLessThan(subject1.startIndex, subject1.endIndex)

        var testIndex = subject1.startIndex
        (0 ..< (UInt.bitWidth - 1)).forEach { _ in subject1.formIndex(after: &testIndex) }
        XCTAssertEqual(testIndex.index, subject1.bits.startIndex)
        XCTAssertEqual(testIndex.mask, 1)
        subject1.formIndex(after: &testIndex)
        XCTAssertEqual(testIndex, subject1.endIndex)

        // A full and partial word.
        subject1 = BitArray(coreWords: [UInt.min, UInt.max], bitCount: UInt.bitWidth + 3, bitIterationDirection: .lo2hi)
        XCTAssertLessThan(subject1.startIndex, subject1.endIndex)
        XCTAssertLessThan(subject1.endIndex.index, subject1.bits.endIndex)
        XCTAssertEqual(subject1.endIndex.mask, UInt.highestOrderBitMask >> 3)

        var counter = 0
        testIndex = subject1.startIndex
        while testIndex < subject1.endIndex {
            subject1.formIndex(after: &testIndex)
            counter += 1
        }
        XCTAssertEqual(counter, UInt.bitWidth + 3)
    }

    // Test index dereferencing for reading elements.
    func testReadElementFromIndex() {
        // Empty.
        var subject1 = BitArray(coreWords: [], bitCount: 0, bitIterationDirection: .lo2hi)
        XCTAssertNil(subject1.first)

        // One bit.
        subject1 = BitArray(word: UInt.max, bitCount: 1, bitIterationDirection: .hi2lo)
        XCTAssertEqual(subject1.first, true)
        XCTAssertTrue(subject1[subject1.startIndex])
        subject1 = BitArray(word: UInt.min, bitCount: 1, bitIterationDirection: .lo2hi)
        XCTAssertEqual(subject1.first, false)
        XCTAssertFalse(subject1[subject1.startIndex])

        // 65 bits.
        let allNybbles: UInt64 = 0x0123456789ABCDEF
        var allNybbleBits = [Bool]()
        (0..<64).forEach { allNybbleBits.append(allNybbles & (UInt64.highestOrderBitMask >> $0) != 0) }
        subject1 = BitArray(words: [allNybbles, UInt64.highestOrderBitMask], bitCount: 65, bitIterationDirection: .hi2lo)
        XCTAssertTrue(subject1.elementsEqual(allNybbleBits + [true]))
    }

    // Test index dereferencing for writing elements.
    func testWriteElementFromIndex() {
        // Basic.
        var subject1 = BitArray(word: UInt.max, bitCount: 1, bitIterationDirection: .lo2hi)
        XCTAssertEqual(subject1.first, true)
        subject1[subject1.startIndex] = false
        XCTAssertEqual(subject1.first, false)
        subject1[subject1.startIndex] = true
        XCTAssertEqual(subject1.first, true)

        // Swap.
        subject1 = BitArray(word: 0x80 as UInt8, bitCount: 2, bitIterationDirection: .hi2lo)
        XCTAssertTrue(subject1.elementsEqual([true, false]))
        subject1.swapAt(subject1.startIndex, subject1.index(after: subject1.startIndex))
        XCTAssertTrue(subject1.elementsEqual([false, true]))

        // Partition.
        subject1 = BitArray(word: 0xAF as UInt8, bitCount: 8, bitIterationDirection: .hi2lo)
        var transitionIndex = subject1.startIndex
        XCTAssertTrue(subject1.elementsEqual([true, false, true, false, true, true, true, true]))
        (0..<2).forEach { _ in subject1.formIndex(after: &transitionIndex) }
        XCTAssertEqual(subject1.partition(by: { $0 }), transitionIndex)
        XCTAssertTrue(subject1.elementsEqual([false, false, true, true, true, true, true, true]))
        (0..<(6 - 2)).forEach { _ in subject1.formIndex(after: &transitionIndex) }
        XCTAssertEqual(subject1.partition(by: { !$0 }), transitionIndex)
        XCTAssertTrue(subject1.elementsEqual([true, true, true, true, true, true, false, false]))
    }

    // Test backward traversal of indices.
    func testBackwardTraversal() {
        // Empty.
        var subject1 = BitArray(coreWords: [], bitCount: 0, bitIterationDirection: .hi2lo)
        XCTAssertNil(subject1.last)

        // Partial word.
        subject1 = BitArray(word: UInt.max, bitCount: 1, bitIterationDirection: .hi2lo)
        XCTAssertLessThan(subject1.startIndex, subject1.endIndex)
        XCTAssertEqual(subject1.index(before: subject1.endIndex), subject1.startIndex)

        // Full word.
        subject1 = BitArray(word: UInt.min, bitCount: UInt.bitWidth, bitIterationDirection: .lo2hi)
        XCTAssertLessThan(subject1.startIndex, subject1.endIndex)
        XCTAssertEqual(subject1.endIndex.index, subject1.bits.endIndex)
        XCTAssertEqual(subject1.endIndex.mask, UInt.highestOrderBitMask)

        var testIndex = subject1.endIndex
        subject1.formIndex(before: &testIndex)
        XCTAssertEqual(testIndex.index, subject1.bits.startIndex)
        XCTAssertEqual(testIndex.mask, 1)
        (0 ..< (UInt.bitWidth - 1)).forEach { _ in subject1.formIndex(before: &testIndex) }
        XCTAssertEqual(testIndex, subject1.startIndex)

        // A full and partial word.
        subject1 = BitArray(coreWords: [UInt.min, UInt.max], bitCount: UInt.bitWidth + 3, bitIterationDirection: .lo2hi)
        XCTAssertLessThan(subject1.startIndex, subject1.endIndex)
        XCTAssertLessThan(subject1.endIndex.index, subject1.bits.endIndex)
        XCTAssertEqual(subject1.endIndex.mask, UInt.highestOrderBitMask >> 3)

        var counter = 0
        testIndex = subject1.endIndex
        while testIndex > subject1.startIndex {
            subject1.formIndex(before: &testIndex)
            counter += 1
        }
        XCTAssertEqual(counter, UInt.bitWidth + 3)

        // Reverse.
        subject1 = BitArray(word: 0xAF as UInt8, bitCount: 8, bitIterationDirection: .hi2lo)
        subject1.reverse()
        XCTAssertEqual(subject1.bits, [UInt(0xF5) << (UInt.bitWidth - 8)])
    }

    // List of tests for Linux.
    static var allTests = [
        ("testPrimaryInitializer", testPrimaryInitializer),

        ("testRemnantTracking", testRemnantTracking),
        ("testHeadExtraction", testHeadExtraction),
        ("testHeadRemoval", testHeadRemoval),
        ("testHeadInsertion", testHeadInsertion),
        ("testTailExtraction", testTailExtraction),
        ("testTailRemoval", testTailRemoval),
        ("testTailInsertion", testTailInsertion),

        ("testWordInitialization", testWordInitialization),
        ("testWordSequenceInitialization", testWordSequenceInitialization),

        ("testDebugPrinting", testDebugPrinting),

        ("testIndexComparisonAndForwardTraversal", testIndexComparisonAndForwardTraversal),
        ("testReadElementFromIndex", testReadElementFromIndex),
        ("testWriteElementFromIndex", testWriteElementFromIndex),
        ("testBackwardTraversal", testBackwardTraversal),
    ]

}
