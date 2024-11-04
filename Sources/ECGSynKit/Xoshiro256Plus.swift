import Foundation

public enum Xoshiro256: Equatable {
    public typealias State = (UInt64, UInt64, UInt64, UInt64)

    internal static var invalidState: State { (0, 0, 0, 0) }

    internal static func isValid(state: State) -> Bool {
        state != invalidState
    }
}

@inlinable
@inline(__always)
internal func rotl(_ x: UInt64, _ k: UInt64) -> UInt64 {
    (x << k) | (x >> (64 &- k))
}

struct Xoshiro256Plus: RandomNumberGenerator {
    public typealias State = Xoshiro256.State

    private var state: State

    public init() {
        var generator = SystemRandomNumberGenerator()
        self.init(seed: generator.next())
    }

    public init(seed: UInt64) {
        var generator = SplitMix64(state: seed)
        var state = Xoshiro256.invalidState

        repeat {
            state = (generator.next(), generator.next(), generator.next(), generator.next())
        } while !Xoshiro256.isValid(state: state)

        self.init(state: state)
    }

    public init(state: State) {
        precondition(Xoshiro256.isValid(state: state), "The state must not be zero")
        self.state = state
    }

    public mutating func next() -> UInt64 {
        let result = state.0 &+ state.3
        let t = state.1 << 17

        state.2 ^= state.0
        state.3 ^= state.1
        state.1 ^= state.2
        state.0 ^= state.3

        state.2 ^= t
        state.3 = rotl(state.3, 45)

        return result
    }
}
