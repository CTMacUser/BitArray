import XCTest
@testable import BitArrayTests

XCTMain([
    testCase(BinaryInteger_ExtensionsTests.allTests),
    testCase(FixedWidthInteger_ExtensionsTests.allTests),
    testCase(BitArrayTests.allTests),
])
