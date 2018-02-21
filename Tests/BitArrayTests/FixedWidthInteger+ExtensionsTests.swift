/*

  FixedWidthInteger+ExtensionsTests.swift
  BitArrayTests

  Created by Daryle Walker on 1/29/18.
  Copyright (c) 2018 Daryle Walker.
  Distributed under the MIT License.

 */

import XCTest
@testable import BitArray


class FixedWidthInteger_ExtensionsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // Test bit-reversal.
    func testBitReversal() {
        // Exhaustive test.  Taken from <https://stackoverflow.com/a/1845062>.
        let octetReversals: [UInt8] = [
            0x00, 0x80, 0x40, 0xC0, 0x20, 0xA0, 0x60, 0xE0, 0x10, 0x90, 0x50, 0xD0, 0x30, 0xB0, 0x70, 0xF0,
            0x08, 0x88, 0x48, 0xC8, 0x28, 0xA8, 0x68, 0xE8, 0x18, 0x98, 0x58, 0xD8, 0x38, 0xB8, 0x78, 0xF8,
            0x04, 0x84, 0x44, 0xC4, 0x24, 0xA4, 0x64, 0xE4, 0x14, 0x94, 0x54, 0xD4, 0x34, 0xB4, 0x74, 0xF4,
            0x0C, 0x8C, 0x4C, 0xCC, 0x2C, 0xAC, 0x6C, 0xEC, 0x1C, 0x9C, 0x5C, 0xDC, 0x3C, 0xBC, 0x7C, 0xFC,
            0x02, 0x82, 0x42, 0xC2, 0x22, 0xA2, 0x62, 0xE2, 0x12, 0x92, 0x52, 0xD2, 0x32, 0xB2, 0x72, 0xF2,
            0x0A, 0x8A, 0x4A, 0xCA, 0x2A, 0xAA, 0x6A, 0xEA, 0x1A, 0x9A, 0x5A, 0xDA, 0x3A, 0xBA, 0x7A, 0xFA,
            0x06, 0x86, 0x46, 0xC6, 0x26, 0xA6, 0x66, 0xE6, 0x16, 0x96, 0x56, 0xD6, 0x36, 0xB6, 0x76, 0xF6,
            0x0E, 0x8E, 0x4E, 0xCE, 0x2E, 0xAE, 0x6E, 0xEE, 0x1E, 0x9E, 0x5E, 0xDE, 0x3E, 0xBE, 0x7E, 0xFE,
            0x01, 0x81, 0x41, 0xC1, 0x21, 0xA1, 0x61, 0xE1, 0x11, 0x91, 0x51, 0xD1, 0x31, 0xB1, 0x71, 0xF1,
            0x09, 0x89, 0x49, 0xC9, 0x29, 0xA9, 0x69, 0xE9, 0x19, 0x99, 0x59, 0xD9, 0x39, 0xB9, 0x79, 0xF9,
            0x05, 0x85, 0x45, 0xC5, 0x25, 0xA5, 0x65, 0xE5, 0x15, 0x95, 0x55, 0xD5, 0x35, 0xB5, 0x75, 0xF5,
            0x0D, 0x8D, 0x4D, 0xCD, 0x2D, 0xAD, 0x6D, 0xED, 0x1D, 0x9D, 0x5D, 0xDD, 0x3D, 0xBD, 0x7D, 0xFD,
            0x03, 0x83, 0x43, 0xC3, 0x23, 0xA3, 0x63, 0xE3, 0x13, 0x93, 0x53, 0xD3, 0x33, 0xB3, 0x73, 0xF3,
            0x0B, 0x8B, 0x4B, 0xCB, 0x2B, 0xAB, 0x6B, 0xEB, 0x1B, 0x9B, 0x5B, 0xDB, 0x3B, 0xBB, 0x7B, 0xFB,
            0x07, 0x87, 0x47, 0xC7, 0x27, 0xA7, 0x67, 0xE7, 0x17, 0x97, 0x57, 0xD7, 0x37, 0xB7, 0x77, 0xF7,
            0x0F, 0x8F, 0x4F, 0xCF, 0x2F, 0xAF, 0x6F, 0xEF, 0x1F, 0x9F, 0x5F, 0xDF, 0x3F, 0xBF, 0x7F, 0xFF
        ]
        XCTAssertEqual((0 ... (0xFF as UInt8)).map { $0.bitReversed() }, octetReversals)

        // Other sizes besides octets.
        let subject2: UInt64 = 0x0123456789ABCDEF
        XCTAssertEqual(subject2.bitReversed(), 0xF7B3D591E6A2C480)

        // Those optional leading zeros count!
        let subject3: UInt32 = 0xFE
        XCTAssertEqual(subject3.bitReversed(), 0x7F000000)
    }

    // Test self-bit-reversal.
    func testBitReversed() {
        // All zeros.
        var subject: UInt8 = 0
        subject.bitReverse()
        XCTAssertEqual(subject, 0)

        // All ones.
        subject = 0xFF
        subject.bitReverse()
        XCTAssertEqual(subject, 0xFF)

        // Asymmetric, single one.
        subject = 0x01
        subject.bitReverse()
        XCTAssertEqual(subject, 0x80)
        subject.bitReverse()
        XCTAssertEqual(subject, 0x01)

        // Asymmetric, multiple ones.
        subject = 0xAD
        subject.bitReverse()
        XCTAssertEqual(subject, 0xB5)
        subject.bitReverse()
        XCTAssertEqual(subject, 0xAD)
    }

    // Test high-order multi-bit masks.
    func testHighOrderBitsMask() {
        XCTAssertEqual((0...8).map { UInt8.highOrderBitsMask(count: $0) }, [0, 0x80, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC, 0xFE, 0xFF])
        XCTAssertEqual(Int16.highOrderBitsMask(count: 14), Int16(bitPattern: 0xFFFC))
    }

    // Test least-significant bit push-up.
    func testLowOrderBitPushing() {
        var sample1: UInt8 = 0xAD
        let trial1 = sample1.pushLowOrderBits(fromHighOrderBitsOf: 0xBB, count: 4)
        XCTAssertEqual(sample1, 0xDB)
        XCTAssertEqual(trial1, 0xA0)

        // All bits.
        let trial2 = sample1.pushLowOrderBits(fromHighOrderBitsOf: 0xEC, count: 8)
        XCTAssertEqual(sample1, 0xEC)
        XCTAssertEqual(trial2, 0xDB)

        // No bits.
        let trial3 = sample1.pushLowOrderBits(fromHighOrderBitsOf: 0xFF, count: 0)
        XCTAssertEqual(sample1, 0xEC)
        XCTAssertEqual(trial3, 0)
    }

    // Test most-significant bit push-down.
    func testHighOrderBitPushing() {
        var sample1: UInt8 = 0xAD
        let trial1 = sample1.pushHighOrderBits(fromLowOrderBitsOf: 0xBB, count: 4)
        XCTAssertEqual(sample1, 0xBA)
        XCTAssertEqual(trial1, 0x0D)

        // All bits.
        let trial2 = sample1.pushHighOrderBits(fromLowOrderBitsOf: 0xEC, count: 8)
        XCTAssertEqual(sample1, 0xEC)
        XCTAssertEqual(trial2, 0xBA)

        // No bits.
        let trial3 = sample1.pushHighOrderBits(fromLowOrderBitsOf: 0xFF, count: 0)
        XCTAssertEqual(sample1, 0xEC)
        XCTAssertEqual(trial3, 0)
    }

    // Test hexadecimal digit width.
    func testHexadecimalDigitCount() {
        XCTAssertEqual(UInt8.hexadecimalDigitCount, 2)
        XCTAssertEqual(UInt16.hexadecimalDigitCount, 4)
        XCTAssertEqual(UInt32.hexadecimalDigitCount, 8)
        XCTAssertEqual(UInt64.hexadecimalDigitCount, 16)
    }

    // Test hexadecimal full-width string.
    func testFullHexadecimalString() {
        XCTAssertEqual((31 as UInt8).fullHexadecimalString, "1F")
        XCTAssertEqual((31 as UInt16).fullHexadecimalString, "001F")
        XCTAssertEqual((31 as UInt32).fullHexadecimalString, "0000001F")
        XCTAssertEqual((31 as UInt64).fullHexadecimalString, "000000000000001F")
    }

    // Test the most-significant bit value.
    func testMostSignificantBit() {
        XCTAssertEqual(UInt8.highestOrderBitMask, 0x80)
        XCTAssertEqual(UInt16.highestOrderBitMask, 0x8000)
        XCTAssertEqual(UInt32.highestOrderBitMask, 0x80000000)
        XCTAssertEqual(UInt64.highestOrderBitMask, 0x8000000000000000)

        XCTAssertEqual(Int8.highestOrderBitMask, Int8.min)
        XCTAssertEqual(Int16.highestOrderBitMask, Int16.min)
        XCTAssertEqual(Int32.highestOrderBitMask, Int32.min)
        XCTAssertEqual(Int64.highestOrderBitMask, Int64.min)
    }

    // List of tests for Linux.
    static var allTests = [
        ("testBitReversal", testBitReversal),
        ("testBitReversed", testBitReversed),

        ("testHighOrderBitsMask", testHighOrderBitsMask),

        ("testLowOrderBitPushing", testLowOrderBitPushing),
        ("testHighOrderBitPushing", testHighOrderBitPushing),

        ("testHexadecimalDigitCount", testHexadecimalDigitCount),
        ("testFullHexadecimalString", testFullHexadecimalString),

        ("testMostSignificantBit", testMostSignificantBit),
    ]

}
