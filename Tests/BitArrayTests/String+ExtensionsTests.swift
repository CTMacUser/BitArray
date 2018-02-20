/*

  String+ExtensionsTests.swift
  BitArrayTests

  Created by Daryle Walker on 2/11/18.
  Copyright (c) 2018 Daryle Walker.
  Distributed under the MIT License.

 */

import XCTest
@testable import BitArray


class String_ExtensionsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // Test left-filling a string with a character to a certain total width.
    func testLeftFill() {
        // Empty source string and total count.
        XCTAssertEqual("".paddingPrepended("*", totalCount: 0), "")

        // Empty source, posititve total count.
        XCTAssertEqual("".paddingPrepended("*", totalCount: 2), "**")

        // Non-empty source; empty, short, equal, excessive total counts.
        XCTAssertEqual("test".paddingPrepended("#", totalCount: 0), "test")
        XCTAssertEqual("test".paddingPrepended("#", totalCount: 1), "test")
        XCTAssertEqual("test".paddingPrepended("#", totalCount: 4), "test")
        XCTAssertEqual("test".paddingPrepended("#", totalCount: 7), "###test")
    }

    // List of tests for Linux.
    static var allTests = [
        ("testLeftFill", testLeftFill),
    ]

}
