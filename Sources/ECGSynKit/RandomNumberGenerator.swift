extension RandomNumberGenerator {
    mutating func nextDouble() -> Double {
        Double(next() >> 11) * 0x1.0p-53
    }

    mutating func nextFloat() -> Float {
        Float(next() >> 40) * 0x1.0p-24
    }
}
