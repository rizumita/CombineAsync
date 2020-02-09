# CombineAsync
Async/Await for Combine

# How to use

## Install

Install as swift package.

## Code

```swift
let p1 = Just<Int>(1)

async { (yield: Yield<Int>) in
    let num = try await(p1)
    yield(num)
    yield(2)
    yield(Just(3))
}.sink(receiveCompletion: { print($0) }) {
    print($0) // 1 -> 2 -> 3
}
```

# License

MIT
