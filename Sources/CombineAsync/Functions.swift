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
public func async<T>(_ body: @escaping (Yield<T>) throws -> ()) -> Async<T> {
    Async(body: body)
}

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public func await<P>(_ publisher: P) throws -> P.Output where P: Publisher {
    try publisher.await()
}
