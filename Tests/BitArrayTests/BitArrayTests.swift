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

    // List of tests for Linux.
    static var allTests = [
        ("testPrimaryInitializer", testPrimaryInitializer),

        ("testRemnantTracking", testRemnantTracking),
        ("testHeadExtraction", testHeadExtraction),
        ("testHeadRemoval", testHeadRemoval),
        ("testHeadInsertion", testHeadInsertion),
    ]

}
