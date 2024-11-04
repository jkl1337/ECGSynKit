import Foundation
import OdeInt
import RealModule

public struct ECGSyn {
    public struct Attractor {
        /// Angle of attractor in radians
        public let θ: Double
        /// Position of extremum above or below the z=0 plane.
        public let a: Double
        /// Width of the attractor.
        public let b: Double
        /// Angle rate factor adjustment `θ * pow(hrMean / 60.0, θrf)`
        public let θrf: Double

        public init(θ: Double, a: Double, b: Double, θrf: Double = 0.0) {
            self.θ = θ
            self.a = a
            self.b = b
            self.θrf = θrf
        }

        public init(deg: Double, a: Double, b: Double, θrf: Double = 0.0) {
            self.init(θ: deg * .pi / 180, a: a, b: b, θrf: θrf)
        }

        static func make(deg: Double, _ a: Double, _ b: Double, _ θrf: Double = 0.0) -> Attractor {
            Attractor(deg: deg, a: a, b: b, θrf: θrf)
        }
    }

    public struct Parameters {
        /// The ECG amplitude in mV.
        public let range: (Double, Double) = (-0.4, 1.2)

        /// Amplitude of the noise.
        public let noiseAmplitude: Double = 0.0

        /// Descriptors of the extrema/attractors for the dynamical model.
        public let attractors: [Attractor] = [
            .make(deg: -70, 1.2, 0.25, 0.25),
            .make(deg: -15, -5.0, 0.1, 0.5),
            .make(deg: 0, 30, 0.1),
            .make(deg: 15, -7.5, 0.1, 0.5),
            .make(deg: 100, 0.75, 0.4, 0.25),
        ]
    }

    public static func generate(params: Parameters, rrSeries: ECGSynRRSeries<Double>) -> [Double] {
        var rng = rrSeries.rng
        let srInternal = rrSeries.timeParameters.srInternal

        let hrSec = rrSeries.timeParameters.hrMean / 60.0
        let hrFact = sqrt(hrSec)

        // adjust extrema parameters for mean heart rate
        let ti = params.attractors.map { $0.θ * pow(hrSec, $0.θrf) }
        let ai = params.attractors.map { $0.a }
        let bi = params.attractors.map { $0.b * hrFact }

        let fhi = rrSeries.rrParamaters.fhi

        let nt = rrSeries.count

        let dt = 1.0 / Double(srInternal)
        let ts = (0 ..< nt).map { Double($0) * dt }
        let x0 = SIMD3<Double>(1.0, 0.0, 0.04)

        let result = SIMD3<Double>.integrate(over: ts, y0: x0, tol: 1e-6) { x, t in
            let ta = atan2(x[1], x[0])

            let r0 = 1.0
            let a0 = 1.0 - sqrt(x[0] * x[0] + x[1] * x[1]) / r0

            let w0 = 2 * .pi / rrSeries.valueAt(t)

            let zbase = 0.005 * sin(2 * .pi * fhi * t)

            var dxdt = SIMD3<Double>(a0 * x[0] - w0 * x[1], a0 * x[1] + w0 * x[0], 0.0)

            for i in 0 ..< ti.count {
                let dt = remainder(ta - ti[i], 2 * .pi)

                dxdt[2] += -ai[i] * dt * exp(-0.5 * (dt * dt) / (bi[i] * bi[i]))
            }
            dxdt[2] += -1.0 * (x[2] - zbase)

            return dxdt
        }

        // extract z and downsample to output sampling frequency
        var zresult = stride(from: 0, to: nt, by: rrSeries.timeParameters.decimateFactor).map { result[$0][2] }

        let (zmin, zmax) = zresult.minAndMax()!
        let zrange = zmax - zmin

        // Scale signal between -0.4 and 1.2 mV
        // add uniformly distributed measurement noise
        for i in 0 ..< zresult.count {
            zresult[i] = (params.range.1 - params.range.0) * (zresult[i] - zmin) / zrange + params.range.0
            zresult[i] += params.noiseAmplitude * (2.0 * rng.nextDouble() - 1.0)
        }
        return zresult
    }
}
