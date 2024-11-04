# ECGSynKit

Swift Package for generating synthetic ECG signals. Includes implementation of ECGSYN [[1]](#1).

# Notes

Implementation roughly corresponds with MATLAB/Java implementation of ECGSYN [[2]](#2) with a few
implementation differences to improve performance. The library is also structured so that expensive
computations can be reused for multiple signals and a single RR series can be reused to generate multi-lead
ECGs.

This implementation generalizes the attractor array to arbitrary size to allow modeling R′ and S′ morphologies.

# Usage

Initialize `TimeParameters` and `RRParameters`:
```swift
import ECGSynKit

let timeParameters = TimeParameters(
    numBeats: 500,
    srInternal: 10, // internal generator sampling rate
    decimateFactor: 2, // decimation factor (output signal sample rate will be `srInternal / decimateFactor`)
    hrMean: 60, // mean heart rate in BPM
    hrStd: 1, // heart rate standard deviation
    seed: 1) // rng seed value
    
let rrParameters = RRParameters(
    flo: 0.1, // low frequency oscillation (Mayer wave) in Hz
    flostd: 0.01, // low frequency oscillation standard deviation
    fhi: 0.25, // high frequency oscillation (respiration) in Hz
    fhistd: 0.01, // high frequency oscillation standard deviation
    lfhfratio: 0.5) // low frequency to high frequency power ratio
```

Initialize an RR Series generator. This will prepare an FFT setup for the required signal size.
Afterwards generate the RR Series:

``` swift
let rrGenerator = ECGSynRRGenerator(params: timeParameters)
let rrSeries = rrGenerator.generateSeries(params: rrParameters)
```

The `rrSeries` can be used multiple times such as to generate multilead ECG signals.


The `attractors` parameter specify the morphology of the exponential extrema of the ECG. For a normal
ECG there are 5 attractors corresponding to PQRST. The parameters `θ`, `a`, `b` are as described in the paper
and are angular position around the signal limit circle, amplitude, and width. The `θrf` parameter is optional
and is a generalization of the stretching factors for `θ`. Each `θ` will be adjusted by `θ * pow(hrMean / 60.0, θrf)`.

``` swift
let params = ECGSyn.Parameters(
    range: (-0.4, 1.2) // the voltage range to scale the signal in mV
    noiseAmplitude: 0.01, // the amplitude of the additive uniform noise
    attractors: [
    // θ, a, b, θrf
        .make(deg: -70, 1.2, 0.25, 0.25),
        .make(deg: -15, -5.0, 0.1, 0.5),
        .make(deg: 0, 30, 0.1),
        .make(deg: 15, -7.5, 0.1, 0.5),
        .make(deg: 100, 0.75, 0.4, 0.25),
    ]
)

let signal = ECGSyn.generate(params: timeParameters) // signal is [Double]
```


# References

<a id="1">[1]</a>
McSharry PE, Clifford GD, Tarassenko L, Smith L. A dynamical model for generating synthetic electrocardiogram signals. IEEE Transactions on Biomedical Engineering 50(3): 289-294; March 2003.

<a id="2">[2]</a>
Goldberger, A., Amaral, L., Glass, L., Hausdorff, J., Ivanov, P. C., Mark, R., ... & Stanley, H. E. (2000). PhysioBank, PhysioToolkit, and PhysioNet: Components of a new research resource for complex physiologic signals. Circulation [Online]. 101 (23), pp. e215–e220.
