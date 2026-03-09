import XCTest
@testable import MemeMill

final class FFmpegProgressParserTests: XCTestCase {

    // MARK: - Time Parsing

    func testParseTimeFromStandardOutput() {
        let line = "frame=  120 fps=30 q=-1.0 Lsize=     256kB time=00:00:04.00 bitrate= 524.3kbits/s speed=1.50x"
        let progress = FFmpegProgressParser.parse(line)
        XCTAssertNotNil(progress)
        XCTAssertEqual(progress?.timeSeconds ?? 0, 4.0, accuracy: 0.01)
    }

    func testParseTimeWithHours() {
        let line = "time=01:23:45.67"
        let progress = FFmpegProgressParser.parse(line)
        XCTAssertNotNil(progress)
        let expected: Double = 1.0 * 3600.0 + 23.0 * 60.0 + 45.0 + 0.67
        XCTAssertEqual(progress?.timeSeconds ?? 0, expected, accuracy: 0.01)
    }

    func testParseTimeZero() {
        let line = "time=00:00:00.00"
        let progress = FFmpegProgressParser.parse(line)
        XCTAssertNotNil(progress)
        XCTAssertEqual(progress?.timeSeconds ?? 1, 0.0, accuracy: 0.01)
    }

    // MARK: - Speed Parsing

    func testParseSpeed() {
        let line = "speed=1.50x"
        let progress = FFmpegProgressParser.parse(line)
        XCTAssertNotNil(progress)
        XCTAssertEqual(progress?.speed ?? 0, 1.5, accuracy: 0.01)
    }

    func testParseSpeedWithSpaces() {
        let line = "speed= 2.30x"
        let progress = FFmpegProgressParser.parse(line)
        XCTAssertNotNil(progress)
        XCTAssertEqual(progress?.speed ?? 0, 2.3, accuracy: 0.01)
    }

    // MARK: - Frame Parsing

    func testParseFrames() {
        let line = "frame=  120 fps=30"
        let progress = FFmpegProgressParser.parse(line)
        XCTAssertNotNil(progress)
        XCTAssertEqual(progress?.framesProcessed, 120)
    }

    func testParseFramesNoSpaces() {
        let line = "frame=45"
        let progress = FFmpegProgressParser.parse(line)
        XCTAssertNotNil(progress)
        XCTAssertEqual(progress?.framesProcessed, 45)
    }

    // MARK: - Combined Parsing

    func testParseFullLine() {
        let line = "frame=  120 fps=30 q=-1.0 Lsize=     256kB time=00:00:04.00 bitrate= 524.3kbits/s speed=1.50x"
        let progress = FFmpegProgressParser.parse(line)
        XCTAssertNotNil(progress)
        XCTAssertEqual(progress?.timeSeconds ?? 0, 4.0, accuracy: 0.01)
        XCTAssertEqual(progress?.speed ?? 0, 1.5, accuracy: 0.01)
        XCTAssertEqual(progress?.framesProcessed, 120)
    }

    // MARK: - No Match

    func testParseReturnsNilForNonProgressLine() {
        let line = "Input #0, mov,mp4,m4a,3gp,3g2,mj2, from 'test.mp4':"
        let progress = FFmpegProgressParser.parse(line)
        XCTAssertNil(progress)
    }

    func testParseReturnsNilForEmptyString() {
        let progress = FFmpegProgressParser.parse("")
        XCTAssertNil(progress)
    }
}
