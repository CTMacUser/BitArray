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

    // List of tests for Linux.
    static var allTests = [
        ("testPrimaryInitializer", testPrimaryInitializer),
    ]

}
