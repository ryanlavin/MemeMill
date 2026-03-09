import XCTest
import AVFoundation
@testable import MemeMill

@MainActor
final class VideoEditorViewModelTests: XCTestCase {

    var mockLoader: MockVideoLoader!
    var viewModel: VideoEditorViewModel!

    override func setUp() {
        super.setUp()
        mockLoader = MockVideoLoader()
        viewModel = VideoEditorViewModel(videoLoader: mockLoader)
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertNil(viewModel.videoSource)
        XCTAssertNil(viewModel.player)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.loadError)
        XCTAssertEqual(viewModel.currentTime, 0)
        XCTAssertFalse(viewModel.isPlaying)
    }

    // MARK: - Load Video

    func testLoadVideoSetsSource() async {
        await viewModel.loadVideo(from: URL(fileURLWithPath: "/test.mp4"))
        XCTAssertNotNil(viewModel.videoSource)
        XCTAssertEqual(viewModel.videoSource?.fileName, "video.mp4")
        XCTAssertNotNil(viewModel.player)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadVideoSetsError() async {
        mockLoader.loadResult = .failure(ExportError.sourceFileNotFound)
        await viewModel.loadVideo(from: URL(fileURLWithPath: "/bad.mp4"))
        XCTAssertNil(viewModel.videoSource)
        XCTAssertNotNil(viewModel.loadError)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadVideoSetsDefaultTimeRange() async {
        await viewModel.loadVideo(from: URL(fileURLWithPath: "/test.mp4"))
        XCTAssertEqual(viewModel.timeRange.start, 0)
        XCTAssertEqual(viewModel.timeRange.end, 5.0)
    }

    func testLoadVideoClipsTimeRangeForShortVideo() async {
        mockLoader.loadResult = .success(VideoSource(
            id: UUID(),
            originalURL: URL(fileURLWithPath: "/test.mp4"),
            playableURL: URL(fileURLWithPath: "/test.mp4"),
            wasRemuxed: false,
            duration: CMTime(seconds: 2, preferredTimescale: 600),
            naturalSize: CGSize(width: 320, height: 240),
            frameRate: 24,
            fileSize: 1000,
            fileName: "short.mp4"
        ))
        await viewModel.loadVideo(from: URL(fileURLWithPath: "/test.mp4"))
        XCTAssertEqual(viewModel.timeRange.end, 2.0)
    }

    // MARK: - Playback

    func testTogglePlayPause() {
        XCTAssertFalse(viewModel.isPlaying)
        viewModel.togglePlayPause()
        // Note: player is nil so play() won't actually play, but state changes
        XCTAssertTrue(viewModel.isPlaying)
        viewModel.togglePlayPause()
        XCTAssertFalse(viewModel.isPlaying)
    }

    // MARK: - Time Markers

    func testSetStartMarkerAtCurrentTime() {
        viewModel.videoSource = makeSource(duration: 60)
        viewModel.currentTime = 10.0
        viewModel.timeRange = TimeRange(start: 0, end: 20)
        viewModel.setStartMarker()
        XCTAssertEqual(viewModel.timeRange.start, 10.0)
        XCTAssertEqual(viewModel.timeRange.end, 20.0)
    }

    func testSetEndMarkerAtCurrentTime() {
        viewModel.videoSource = makeSource(duration: 60)
        viewModel.currentTime = 15.0
        viewModel.timeRange = TimeRange(start: 5, end: 20)
        viewModel.setEndMarker()
        XCTAssertEqual(viewModel.timeRange.start, 5.0)
        XCTAssertEqual(viewModel.timeRange.end, 15.0)
    }

    func testSetStartMarkerAfterEndAutoAdjustsEnd() {
        viewModel.videoSource = makeSource(duration: 60)
        viewModel.timeRange = TimeRange(start: 0, end: 10)
        viewModel.setStartMarker(at: 15.0)
        XCTAssertEqual(viewModel.timeRange.start, 15.0)
        XCTAssertGreaterThan(viewModel.timeRange.end, viewModel.timeRange.start)
    }

    func testSetEndMarkerBeforeStartAutoAdjustsStart() {
        viewModel.videoSource = makeSource(duration: 60)
        viewModel.timeRange = TimeRange(start: 10, end: 20)
        viewModel.setEndMarker(at: 5.0)
        XCTAssertEqual(viewModel.timeRange.end, 5.0)
        XCTAssertLessThan(viewModel.timeRange.start, viewModel.timeRange.end)
    }

    // MARK: - Step Frame

    func testStepFrameForward() {
        viewModel.videoSource = makeSource(duration: 60, frameRate: 24)
        viewModel.currentTime = 10.0
        viewModel.stepFrame(forward: true)
        XCTAssertGreaterThan(viewModel.currentTime, 10.0)
    }

    func testStepFrameBackward() {
        viewModel.videoSource = makeSource(duration: 60, frameRate: 24)
        viewModel.currentTime = 10.0
        viewModel.stepFrame(forward: false)
        XCTAssertLessThan(viewModel.currentTime, 10.0)
    }

    func testStepFrameForwardClampsToEnd() {
        viewModel.videoSource = makeSource(duration: 10)
        viewModel.currentTime = 10.0
        viewModel.stepFrame(forward: true)
        XCTAssertEqual(viewModel.currentTime, 10.0)
    }

    func testStepFrameBackwardClampsToZero() {
        viewModel.videoSource = makeSource(duration: 10)
        viewModel.currentTime = 0.0
        viewModel.stepFrame(forward: false)
        XCTAssertEqual(viewModel.currentTime, 0.0)
    }

    // MARK: - Helpers

    private func makeSource(duration: Double, frameRate: Float = 24) -> VideoSource {
        VideoSource(
            id: UUID(),
            originalURL: URL(fileURLWithPath: "/test.mp4"),
            playableURL: URL(fileURLWithPath: "/test.mp4"),
            wasRemuxed: false,
            duration: CMTime(seconds: duration, preferredTimescale: 600),
            naturalSize: CGSize(width: 1920, height: 1080),
            frameRate: frameRate,
            fileSize: 10_000_000,
            fileName: "test.mp4"
        )
    }
}
