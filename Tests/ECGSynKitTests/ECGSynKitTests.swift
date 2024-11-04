import Testing
@testable import ECGSynKit
import PFFFT
import ComplexModule
import Foundation

@Test func ecgSynTest ()  {
    let timeParameters = TimeParameters()
    let rrParameters = RRParameters()

    var rrg = ECGSynRRGenerator(params: timeParameters)

    let parameters = ECGSyn.Parameters()
    let ecg = ECGSyn.generate(params: parameters, rrSeries: rrg.generateSeries(params: rrParameters))
    // write ecg to file
    let url = URL(fileURLWithPath: "ecg.txt")
    let ecgString = ecg.map { String($0) }.joined(separator: "\n")
    try! ecgString.write(to: url, atomically: true, encoding: .utf8)
}
