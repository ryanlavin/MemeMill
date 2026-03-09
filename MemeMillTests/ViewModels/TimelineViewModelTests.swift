import XCTest
import AVFoundation
@testable import MemeMill

@MainActor
final class TimelineViewModelTests: XCTestCase {

    var viewModel: TimelineViewModel!

    override func setUp() {
        super.setUp()
        let generator = ThumbnailGenerator()
        viewModel = TimelineViewModel(generator: generator)
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertTrue(viewModel.thumbnails.isEmpty)
        XCTAssertFalse(viewModel.isGenerating)
    }

    // MARK: - Position Mapping

    func testTimeForPositionAtStart() {
        let time = viewModel.timeForPosition(0, totalWidth: 800, duration: 60)
        XCTAssertEqual(time, 0, accuracy: 0.01)
    }

    func testTimeForPositionAtEnd() {
        let time = viewModel.timeForPosition(800, totalWidth: 800, duration: 60)
        XCTAssertEqual(time, 60, accuracy: 0.01)
    }

    func testTimeForPositionAtMiddle() {
        let time = viewModel.timeForPosition(400, totalWidth: 800, duration: 60)
        XCTAssertEqual(time, 30, accuracy: 0.01)
    }

    func testTimeForPositionNegativeClampsToZero() {
        let time = viewModel.timeForPosition(-100, totalWidth: 800, duration: 60)
        XCTAssertEqual(time, 0, accuracy: 0.01)
    }

    func testTimeForPositionBeyondEndClampsToDuration() {
        let time = viewModel.timeForPosition(1000, totalWidth: 800, duration: 60)
        XCTAssertEqual(time, 60, accuracy: 0.01)
    }

    func testTimeForPositionZeroWidth() {
        let time = viewModel.timeForPosition(100, totalWidth: 0, duration: 60)
        XCTAssertEqual(time, 0, accuracy: 0.01)
    }

    // MARK: - Position for Time

    func testPositionForTimeAtStart() {
        let pos = viewModel.positionForTime(0, totalWidth: 800, duration: 60)
        XCTAssertEqual(pos, 0, accuracy: 0.01)
    }

    func testPositionForTimeAtEnd() {
        let pos = viewModel.positionForTime(60, totalWidth: 800, duration: 60)
        XCTAssertEqual(pos, 800, accuracy: 0.01)
    }

    func testPositionForTimeAtMiddle() {
        let pos = viewModel.positionForTime(30, totalWidth: 800, duration: 60)
        XCTAssertEqual(pos, 400, accuracy: 0.01)
    }

    func testPositionForTimeZeroDuration() {
        let pos = viewModel.positionForTime(10, totalWidth: 800, duration: 0)
        XCTAssertEqual(pos, 0, accuracy: 0.01)
    }

    // MARK: - Thumbnail Generation

    func testGenerateThumbnailsWithRealVideo() async throws {
        let testURL = try createTestVideo()
        defer { try? FileManager.default.removeItem(at: testURL) }

        let asset = AVURLAsset(url: testURL)
        viewModel.generateThumbnails(for: asset, count: 5)

        // Wait for generation to complete
        try await Task.sleep(nanoseconds: 2_000_000_000)

        XCTAssertFalse(viewModel.isGenerating)
        XCTAssertFalse(viewModel.thumbnails.isEmpty)
    }

    func testCancelStopsGeneration() {
        viewModel.cancel()
        // Just verify it doesn't crash
        XCTAssertTrue(viewModel.thumbnails.isEmpty)
    }

    // MARK: - Helper

    private func createTestVideo() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let outputURL = tempDir.appendingPathComponent("timeline_test.mp4")
        try? FileManager.default.removeItem(at: outputURL)

        let ffmpegURL = FFmpegLocator.locate()!
        let process = Process()
        process.executableURL = ffmpegURL
        process.arguments = [
            "-f", "lavfi",
            "-i", "testsrc=duration=2:size=320x240:rate=24",
            "-c:v", "libx264",
            "-pix_fmt", "yuv420p",
            "-y",
            outputURL.path
        ]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        try process.run()
        process.waitUntilExit()
        return outputURL
    }
}
