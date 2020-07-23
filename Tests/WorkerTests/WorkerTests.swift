import XCTest
@testable import Worker

final class WorkerTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Worker().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
