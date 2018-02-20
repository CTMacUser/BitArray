import XCTest
@testable import BitArrayTests

XCTMain([
    testCase(String_ExtensionsTests.allTests),
    testCase(BinaryInteger_ExtensionsTests.allTests),
    testCase(FixedWidthInteger_ExtensionsTests.allTests),
    testCase(BitArrayTests.allTests),
])
