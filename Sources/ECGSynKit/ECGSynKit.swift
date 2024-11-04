import Algorithms
import ComplexModule
import RealModule
import Foundation
import PFFFT

public struct TimeParameters {
    /// The number of beats to simulate.
    let numBeats: Int = 12

    /// The internal sampling frequency in Hz.
    let srInternal: Int = 512

    /// Output decimation factor
    let decimateFactor: Int = 2

    /// The mean heart rate in beats per minute.
    let hrMean: Double = 60.0

    /// The standard deviation of the heart rate.
    let hrStd: Double = 1.0

    /// RNG seed value.
    let seed: UInt64 = 8
}

public struct RRParameters {
    /// Mayer wave frequency in Hz.
    let flo = 0.1

    /// flo standard deviation.
    let flostd = 0.01

    /// Respiratory rate frequency in Hz.
    let fhi = 0.25

    /// fhi standard deviation.
    let fhistd = 0.01

    /// The ratio of power between low and high frequencies.
    let lfhfRatio: Double = 0.5
}

func stdev(_ data: [Double]) -> Double {
    let n = Double(data.count)
    let mean = data.reduce(0.0, +) / n
    return sqrt(data.lazy.map { ($0 - mean) * ($0 - mean) }.reduce(0.0, +) / (n - 1))
}
