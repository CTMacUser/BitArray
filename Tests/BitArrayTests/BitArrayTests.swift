import XCTest
@testable import BitArray

class BitArrayTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(BitArray().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
