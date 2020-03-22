//
//  File.swift
//  
//
//  Created by 和泉田 領一 on 2020/02/09.
//

import Foundation
#if canImport(Combine)
import Combine
#endif

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension Publisher {
    @discardableResult
    func await() throws -> Output {
        var output: Output?
        var error: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let c = subscribe(on: DispatchQueue.global()).first()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    ()
                case .failure(let e):
                    error = e
                }
                semaphore.signal()
            }, receiveValue: {
                output = $0
            })
        
        _ = semaphore.wait(timeout: .distantFuture)
        
        guard let result = output else { throw error! }
        return result
    }
}
