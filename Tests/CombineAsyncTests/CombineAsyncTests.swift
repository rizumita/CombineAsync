import XCTest
import Combine
@testable import CombineAsync

final class CombineAsyncTests: XCTestCase {
    func testAsyncAwait() {
        let exp = expectation(description: #function)
        
        let p1 = Just<Int>(1)

        let c = async { (yield: Yield<Int>) in
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

        let c = async { (yield: Yield<Int>) in
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
    
    func testAsyncAwaitPublisher() {
        let exp = expectation(description: #function)
        exp.expectedFulfillmentCount = 5

        let p = Timer.publish(every: 0.1, on: RunLoop.main, in: .default).autoconnect().prefix(5)

        let c = async { (yield: Yield<Date>) in
            yield(p)
        }.sink(receiveCompletion: { _ in }) { date in
            print(date)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testAsyncAwaitFuture() {
        let exp = expectation(description: #function)

        let future: Deferred<Future<Int, Never>> = Deferred {
            Future { promise in
                DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                    promise(.success(1))
                }
            }
        }
        
        var num = 0
        let c = async { (yield: Yield<()>) in
            num = try await(future)
        }.sink(receiveCompletion: { _ in
            XCTAssertEqual(num, 1)
            exp.fulfill()
        }, receiveValue: {})
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testAsyncAwaitVoid() {
        var flag = false
        let c = async { (yield: Yield<()>) in
            flag = true
        }.sink(receiveCompletion: { _ in
            XCTAssertTrue(flag)
        }, receiveValue: {})
    }
    
    func testAsyncAwaitMainThread() {
        let exp = expectation(description: #function)
        
        let future: Deferred<Future<Int, Never>> = Deferred {
            Future { promise in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    promise(.success(1))
                }
            }
        }

        var num = 0
        let c = async { (yield: Yield<()>) in
            num = try await(future.subscribe(on: DispatchQueue.main))
        }.subscribe(on: DispatchQueue.main).sink(receiveCompletion: { _ in
            XCTAssertEqual(num, 1)
            exp.fulfill()
        }, receiveValue: {})
        
        waitForExpectations(timeout: 2.0)
        
        print("end")
    }

    static var allTests = [
        ("testExample", testAsyncAwait),
    ]
}
