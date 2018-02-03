/*

  BinaryInteger+ExtensionsTests.swift
  BitArrayTests

  Created by Daryle Walker on 1/29/18.
  Copyright (c) 2018 Daryle Walker.
  Distributed under the MIT License.

 */

import XCTest
@testable import BitArray


class BinaryInteger_ExtensionsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // Test low-order multi-bit masks.
    func testLowOrderBitsMask() {
        XCTAssertEqual((0...8).map { UInt8.lowOrderBitsMask(count: $0) }, [0, 1, 3, 7, 0xF, 0x1F, 0x3F, 0x7F, 0xFF])
        XCTAssertEqual(Int16.lowOrderBitsMask(count: 14), 0x3FFF)
    }

    // Test assigning selected bits.
    func testReplacingBits() {
        var sample1: UInt8 = 0x5D
        let oldSample1Targeted = sample1.replaceBits(with: 0xAA, forOnly: 0xF0)
        XCTAssertEqual(sample1, 0xAD)
        XCTAssertEqual(oldSample1Targeted, 0x50)
    }

    // List of tests for Linux.
    static var allTests = [
        ("testLowOrderBitsMask", testLowOrderBitsMask),

        ("testReplacingBits", testReplacingBits),
    ]

}
