import XCTest
@testable import MemeMill

final class FFmpegLocatorTests: XCTestCase {

    func testLocateReturnsNonNilOnSystemWithFFmpeg() {
        let url = FFmpegLocator.locate()
        // This test assumes FFmpeg is installed via Homebrew
        XCTAssertNotNil(url, "FFmpeg should be found on this system")
    }

    func testLocateReturnsExecutableFile() {
        guard let url = FFmpegLocator.locate() else {
            XCTFail("FFmpeg not found")
            return
        }
        XCTAssertTrue(
            FileManager.default.isExecutableFile(atPath: url.path),
            "FFmpeg path should point to an executable file"
        )
    }

    func testLocateReturnsPathContainingFFmpeg() {
        guard let url = FFmpegLocator.locate() else {
            XCTFail("FFmpeg not found")
            return
        }
        XCTAssertTrue(
            url.lastPathComponent == "ffmpeg",
            "Located binary should be named 'ffmpeg'"
        )
    }
}
