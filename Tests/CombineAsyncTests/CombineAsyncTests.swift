import XCTest
import Combine
@testable import CombineAsync

final class CombineAsyncTests: XCTestCase {
    func testAsyncAwait() {
        let exp = expectation(description: #function)
        
        let p1 = Just<Int>(1)

        _ = async { (yield: Yield<Int>) in
            let num = try await(p1)
            yield(num)
            yield(2)
            yield(Just(3))
        }.collect().sink(receiveCompletion: { print($0) }) {
            XCTAssertEqual([1, 2, 3], $0)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testAsyncAwaitThrow() {
        let exp = expectation(description: #function)
        exp.expectedFulfillmentCount = 4
        
        var count = 1
        
        let p1 = Just<Int>(1)

        _ = async { (yield: Yield<Int>) in
            let num = try await(p1)
            yield(num)
            yield(2)
            yield(Just(3))
            throw NSError(domain: "error", code: 0)
        }.sink(receiveCompletion: {
            switch $0 {
            case .finished:
                XCTFail()
            case .failure(let error as NSError):
                XCTAssertEqual(error.domain, "error")
                XCTAssertEqual(error.code, 0)
                exp.fulfill()
            }
        }) { num in
            XCTAssertEqual(count, num)
            count += 1
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }

    static var allTests = [
        ("testExample", testAsyncAwait),
    ]
}
