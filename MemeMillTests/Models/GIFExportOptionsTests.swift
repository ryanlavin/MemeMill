import XCTest
@testable import MemeMill

final class GIFExportOptionsTests: XCTestCase {

    // MARK: - Defaults

    func testDefaultValues() {
        let options = GIFExportOptions.default
        XCTAssertEqual(options.fps, 15)
        XCTAssertEqual(options.scale, .half)
        XCTAssertEqual(options.quality, .high)
        XCTAssertEqual(options.speed, 1.0)
        XCTAssertEqual(options.loopCount, 0)
    }

    // MARK: - Resolution Scale

    func testResolutionScaleMultipliers() {
        XCTAssertEqual(ResolutionScale.quarter.multiplier, 0.25, accuracy: 0.001)
        XCTAssertEqual(ResolutionScale.third.multiplier, 1.0 / 3.0, accuracy: 0.001)
        XCTAssertEqual(ResolutionScale.half.multiplier, 0.5, accuracy: 0.001)
        XCTAssertEqual(ResolutionScale.twoThirds.multiplier, 2.0 / 3.0, accuracy: 0.001)
        XCTAssertEqual(ResolutionScale.full.multiplier, 1.0, accuracy: 0.001)
    }

    func testResolutionScaleAllCases() {
        XCTAssertEqual(ResolutionScale.allCases.count, 5)
    }

    func testResolutionScaleRawValues() {
        XCTAssertEqual(ResolutionScale.quarter.rawValue, "25%")
        XCTAssertEqual(ResolutionScale.half.rawValue, "50%")
        XCTAssertEqual(ResolutionScale.full.rawValue, "100%")
    }

    // MARK: - GIF Quality

    func testGIFQualityStatsModes() {
        XCTAssertEqual(GIFQuality.low.statsMode, "full")
        XCTAssertEqual(GIFQuality.medium.statsMode, "full")
        XCTAssertEqual(GIFQuality.high.statsMode, "diff")
        XCTAssertEqual(GIFQuality.maximum.statsMode, "diff")
    }

    func testGIFQualityDitherAlgorithms() {
        XCTAssertEqual(GIFQuality.low.ditherAlgorithm, "bayer")
        XCTAssertEqual(GIFQuality.medium.ditherAlgorithm, "sierra2_4a")
        XCTAssertEqual(GIFQuality.high.ditherAlgorithm, "floyd_steinberg")
        XCTAssertEqual(GIFQuality.maximum.ditherAlgorithm, "sierra3")
    }

    func testGIFQualityAllCases() {
        XCTAssertEqual(GIFQuality.allCases.count, 4)
    }

    // MARK: - Codable

    func testCodableRoundTrip() throws {
        let original = GIFExportOptions(
            fps: 24,
            scale: .twoThirds,
            quality: .maximum,
            speed: 1.5,
            loopCount: 3
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GIFExportOptions.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testDefaultOptionsCodableRoundTrip() throws {
        let original = GIFExportOptions.default
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GIFExportOptions.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - Equatable

    func testEquality() {
        let a = GIFExportOptions(fps: 15, scale: .half, quality: .high, speed: 1.0, loopCount: 0)
        let b = GIFExportOptions(fps: 15, scale: .half, quality: .high, speed: 1.0, loopCount: 0)
        XCTAssertEqual(a, b)
    }

    func testInequalityFPS() {
        let a = GIFExportOptions(fps: 15, scale: .half, quality: .high, speed: 1.0, loopCount: 0)
        let b = GIFExportOptions(fps: 30, scale: .half, quality: .high, speed: 1.0, loopCount: 0)
        XCTAssertNotEqual(a, b)
    }
}
