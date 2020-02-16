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
        subscriber.receive(subscription: AsyncSubscription<T>(subscriber: AnySubscriber(subscriber), yield: yield, body: body))
    }
    
    private class AsyncSubscription<T>: Subscription {
        internal init(subscriber: AnySubscriber<T, Error>, yield: Yield<T>, body: @escaping (Yield<T>) throws -> ()) {
            self.subscriber = subscriber
            self.yield = yield
            self.body = body
            
            yield.subject.sink(receiveCompletion: {
                switch $0 {
                case .finished:
                    subscriber.receive(completion: .finished)
                case .failure(let error):
                    subscriber.receive(completion: .failure(error))
                }
            }, receiveValue: {
                _ = subscriber.receive($0)
            }).store(in: &cancellables)
        }
        
        deinit {
            self.yield.subject.send(completion: .finished)
        }
        
        private var cancellables = Set<AnyCancellable>()
        private let subscriber: AnySubscriber<T, Error>
        private let yield: Yield<T>
        private let body: (Yield<T>) throws -> ()
        private var endCancellable: AnyCancellable?
        
        func request(_ demand: Subscribers.Demand) {
            do {
                try body(yield)
                
                if let yield = yield as? Yield<()> {
                    yield(())
                }
                
                endCancellable = yield.$allPublishersEnded
                    .filter { $0 }
                    .sink(receiveValue: { [unowned yield] _ in yield.subject.send(completion: .finished) })
            } catch {
                yield.subject.send(completion: .failure(error))
            }
        }
        
        func cancel() {
            endCancellable?.cancel()
            yield.subject.send(completion: .finished)
            yield.cancellables.forEach { $0.cancel() }
        }
    }
}
