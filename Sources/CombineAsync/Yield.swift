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
    var cancellables = Set<AnyCancellable>()
    
    @Published var allPublishersEnded: Bool = false
    
    var publisherCount = 0 {
        didSet {
            allPublishersEnded = false
        }
    }
    private var endCount = 0 {
        didSet {
            allPublishersEnded = publisherCount == endCount
        }
    }
    private let queue = DispatchQueue(label: "CombineAsync.Yield.queue")
    
    public func callAsFunction(_ value: T) {
        subject.send(value)
    }
    
    public func callAsFunction<P>(_ publisher: P) where P: Publisher, P.Output == T {
        run(on: queue) {
            self.publisherCount += 1
        }
        
        publisher.mapError { $0 as Error }
            .handleEvents(receiveCompletion: { [weak self] _ in
                guard let `self` = self else { return }
                run(on: self.queue) {
                    self.endCount += 1
                }
                }, receiveCancel: { [weak self] in
                    guard let `self` = self else { return }
                    run(on: self.queue) {
                        self.endCount += 1
                    }
            })
            .sink(receiveCompletion: { [weak self] in
                switch $0 {
                case .finished:
                    ()
                case .failure(let error):
                    self?.subject.send(completion: .failure(error))
                }
                }, receiveValue: { [weak self] in
                    self?.subject.send($0)
            }).store(in: &cancellables)
    }
}

func run(on queue: DispatchQueue, _ f: @escaping () -> ()) {
    let label = String(cString: __dispatch_queue_get_label(queue), encoding: .utf8)
    
    if label == queue.label {
        f()
    } else {
        queue.sync {
            f()
        }
    }
}
