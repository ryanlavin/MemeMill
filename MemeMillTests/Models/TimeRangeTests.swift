import XCTest
import AVFoundation
@testable import MemeMill

final class TimeRangeTests: XCTestCase {

    // MARK: - Duration

    func testDurationCalculation() {
        let range = TimeRange(start: 2.0, end: 5.0)
        XCTAssertEqual(range.duration, 3.0, accuracy: 0.001)
    }

    func testDurationNeverNegative() {
        let range = TimeRange(start: 5.0, end: 2.0)
        XCTAssertEqual(range.duration, 0.0)
    }

    func testDurationZeroWhenStartEqualsEnd() {
        let range = TimeRange(start: 3.0, end: 3.0)
        XCTAssertEqual(range.duration, 0.0)
    }

    // MARK: - Validity

    func testIsValidWithValidRange() {
        let range = TimeRange(start: 1.0, end: 4.0)
        XCTAssertTrue(range.isValid)
    }

    func testIsValidFalseWhenStartEqualsEnd() {
        let range = TimeRange(start: 3.0, end: 3.0)
        XCTAssertFalse(range.isValid)
    }

    func testIsValidFalseWhenStartAfterEnd() {
        let range = TimeRange(start: 5.0, end: 2.0)
        XCTAssertFalse(range.isValid)
    }

    // MARK: - GIF Duration Limit

    func testIsWithinGIFLimitForShortRange() {
        let range = TimeRange(start: 0, end: 10.0)
        XCTAssertTrue(range.isWithinGIFLimit)
    }

    func testIsWithinGIFLimitAtExactLimit() {
        let range = TimeRange(start: 0, end: 30.0)
        XCTAssertTrue(range.isWithinGIFLimit)
    }

    func testIsWithinGIFLimitFalseForLongRange() {
        let range = TimeRange(start: 0, end: 31.0)
        XCTAssertFalse(range.isWithinGIFLimit)
    }

    func testMaxGIFDuration() {
        XCTAssertEqual(TimeRange.maxGIFDuration, 30.0)
    }

    // MARK: - Clamping

    func testClampedWithinBounds() {
        let range = TimeRange(start: 2.0, end: 5.0)
        let clamped = range.clamped(to: 10.0)
        XCTAssertEqual(clamped.start, 2.0)
        XCTAssertEqual(clamped.end, 5.0)
    }

    func testClampedEndExceedsVideoDuration() {
        let range = TimeRange(start: 2.0, end: 15.0)
        let clamped = range.clamped(to: 10.0)
        XCTAssertEqual(clamped.start, 2.0)
        XCTAssertEqual(clamped.end, 10.0)
    }

    func testClampedBothExceedVideoDuration() {
        let range = TimeRange(start: 12.0, end: 15.0)
        let clamped = range.clamped(to: 10.0)
        XCTAssertEqual(clamped.start, 10.0)
        XCTAssertEqual(clamped.end, 10.0)
    }

    func testClampedNegativeStartBecomesZero() {
        let range = TimeRange(start: -5.0, end: 5.0)
        let clamped = range.clamped(to: 10.0)
        XCTAssertEqual(clamped.start, 0.0)
        XCTAssertEqual(clamped.end, 5.0)
    }

    // MARK: - CMTimeRange Conversion

    func testCMTimeRangeConversion() {
        let range = TimeRange(start: 1.0, end: 4.0)
        let cmRange = range.cmTimeRange
        XCTAssertEqual(CMTimeGetSeconds(cmRange.start), 1.0, accuracy: 0.01)
        XCTAssertEqual(CMTimeGetSeconds(cmRange.duration), 3.0, accuracy: 0.01)
    }

    // MARK: - Codable

    func testCodableRoundTrip() throws {
        let original = TimeRange(start: 1.5, end: 7.3)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TimeRange.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - Equatable

    func testEquality() {
        let a = TimeRange(start: 1.0, end: 5.0)
        let b = TimeRange(start: 1.0, end: 5.0)
        XCTAssertEqual(a, b)
    }

    func testInequality() {
        let a = TimeRange(start: 1.0, end: 5.0)
        let b = TimeRange(start: 1.0, end: 6.0)
        XCTAssertNotEqual(a, b)
    }
}
