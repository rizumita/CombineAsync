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
public class Yield<T> {
    let subject = PassthroughSubject<T, Error>()
    private var cancellables = Set<AnyCancellable>()
    
    public func callAsFunction(_ value: T) {
        subject.send(value)
    }
    
    public func callAsFunction<P>(_ publisher: P) where P: Publisher, P.Output == T {
        publisher.mapError { $0 as Error }
            .sink(receiveCompletion: { [weak self] in
                switch $0 {
                case .finished:
                    ()
                case .failure(let error):
                    self?.subject.send(completion: .failure(error))
                }
            }, receiveValue: { [weak self] in self?.subject.send($0) }).store(in: &cancellables)
    }
}
