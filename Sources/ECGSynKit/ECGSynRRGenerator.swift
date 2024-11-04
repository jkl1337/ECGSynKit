import ComplexModule
import Foundation
import PFFFT
import RealModule

public struct ECGSynRRGenerator: ~Copyable {
    let nrr: Int

    let fft: FFT<Double>
    let spectrum: Buffer<Complex<Double>>
    let signal: Buffer<Double>

    var rng: RandomNumberGenerator

    // mean and standard deviation of RR intervals
    let rrMean: Double
    let rrStd: Double

    let timeParameters: TimeParameters

    public init(params: TimeParameters) {
        typealias FFT = PFFFT.FFT<Double>

        let sr = params.srInternal
        rrMean = 60.0 / params.hrMean
        rrStd = 60.0 * params.hrStd / (params.hrMean * params.hrMean)

        nrr = FFT.nearestValidSize(params.numBeats * sr * Int(rrMean.rounded(.up)), higher: true)
        fft = try! FFT(n: nrr)
        spectrum = fft.makeSpectrumBuffer(extra: 1)
        signal = fft.makeSignalBuffer()

        timeParameters = params
        rng = Xoshiro256Plus(seed: params.seed)
    }

    public mutating func generateSeries(params: RRParameters) -> ECGSynRRSeries<Double> {
        let rr = generateSignal(params: params)
        return ECGSynRRSeries(timeParameters: timeParameters, rrParamaters: params, rng: rng, signal: rr)
    }

    public mutating func generateSignal(params: RRParameters) -> [Double] {
        let w1 = 2.0 * .pi * params.flo
        let w2 = 2.0 * .pi * params.fhi
        let c1 = 2.0 * .pi * params.flostd
        let c2 = 2.0 * .pi * params.fhistd

        let sig2 = 1.0
        let sig1 = params.lfhfRatio

        let sr = Double(timeParameters.srInternal)

        let dw = (sr / Double(nrr)) * 2.0 * .pi

        spectrum.mapInPlaceSwapLast { i in
            let w = dw * Double(i)

            let dw1 = w - w1
            let dw2 = w - w2
            let hw = sig1 * exp(-dw1 * dw1 / (2.0 * c1 * c1)) / sqrt(2.0 * .pi * c1 * c1)
                + sig2 * exp(-dw2 * dw2 / (2.0 * c2 * c2)) / sqrt(2.0 * .pi * c2 * c2)

            let sw = (sr / 2.0) * sqrt(hw)
            let ph = 2.0 * .pi * rng.nextDouble()

            return Complex(length: sw, phase: ph)
        }

        fft.inverse(spectrum: spectrum, signal: signal)

        var rr = signal.map { $0 * 1.0 / Double(nrr) }

        let xstd = stdev(rr)
        let ratio = rrStd / xstd

        for i in 0 ..< nrr {
            rr[i] = rr[i] * ratio + rrMean
        }
        return rr
    }
}
