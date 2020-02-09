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
public class Async<T>: Publisher {
    public typealias Output = T
    public typealias Failure = Error
    
    private let yield = Yield<T>()
    private let body: (Yield<T>) throws -> ()
    
    public init(body: @escaping (Yield<T>) throws -> ()) {
        self.body = body
    }
    
    public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        yield.subject.subscribe(subscriber)
        subscriber.receive(subscription: Subscriptions.empty)
        do {
            try body(yield)
            yield.subject.send(completion: .finished)
        } catch {
            yield.subject.send(completion: .failure(error))
        }
    }
}
