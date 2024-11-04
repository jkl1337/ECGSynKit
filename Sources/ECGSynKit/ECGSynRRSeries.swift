import Foundation
import RealModule
import Algorithms

public struct ECGSynRRSeries<T: BinaryFloatingPoint> {
    let timeParameters: TimeParameters
    let rrParamaters: RRParameters
    let rng: RandomNumberGenerator
    let count: Int

    struct Segment {
        let end: T
        let value: T
    }
    let segments: [Segment]

    public init(timeParameters: TimeParameters, rrParamaters: RRParameters, rng: RandomNumberGenerator, signal: [T]) {
        self.timeParameters = timeParameters
        self.rrParamaters = rrParamaters
        self.rng = rng

        let sr = T(timeParameters.srInternal)

        var rrn = [Segment]()
        // generate piecewise RR time series
        do {
            var tecg = T.zero
            var i = 0
            while i < signal.count {
                tecg += signal[i]
                rrn.append(Segment(end: tecg, value: signal[i]))
                i = Int((tecg * sr).rounded(.toNearestOrEven)) + 1
            }
        }

        segments = rrn
        count = signal.count
    }

    @inline(__always)
    public func valueAt(_ t: T) -> T {
        let index = min(segments.partitioningIndex { t < $0.end }, segments.endIndex - 1)
        return segments[index].value
    }

}
