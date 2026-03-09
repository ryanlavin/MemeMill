import XCTest
@testable import MemeMill

final class VideoLoaderServiceTests: XCTestCase {

    var mockFFmpeg: MockFFmpegService!
    var loader: VideoLoaderService!

    override func setUp() {
        super.setUp()
        mockFFmpeg = MockFFmpegService()
        loader = VideoLoaderService(ffmpeg: mockFFmpeg)
    }

    override func tearDown() {
        loader.cleanupTemporaryFiles()
        loader = nil
        mockFFmpeg = nil
        super.tearDown()
    }

    // MARK: - Extension Classification

    func testMP4DoesNotTriggerRemux() async throws {
        // Create a minimal test MP4 using FFmpeg
        let testURL = try await createTestVideo(extension: "mp4")
        defer { try? FileManager.default.removeItem(at: testURL) }

        // Use real FFmpeg for this test since we need actual AVFoundation loading
        let realFFmpeg = FFmpegService()
        let realLoader = VideoLoaderService(ffmpeg: realFFmpeg)

        let source = try await realLoader.load(from: testURL)
        XCTAssertFalse(source.wasRemuxed)
        XCTAssertEqual(source.originalURL, testURL)
        XCTAssertEqual(source.playableURL, testURL)
        XCTAssertEqual(source.fileName, testURL.lastPathComponent)
        realLoader.cleanupTemporaryFiles()
    }

    func testMKVTriggersRemux() async throws {
        let testURL = try await createTestVideo(extension: "mkv")
        defer { try? FileManager.default.removeItem(at: testURL) }

        let realFFmpeg = FFmpegService()
        let realLoader = VideoLoaderService(ffmpeg: realFFmpeg)

        let source = try await realLoader.load(from: testURL)
        XCTAssertTrue(source.wasRemuxed)
        XCTAssertEqual(source.originalURL, testURL)
        XCTAssertNotEqual(source.playableURL, testURL)
        XCTAssertTrue(source.playableURL.pathExtension == "mp4")
        realLoader.cleanupTemporaryFiles()
    }

    func testVideoSourceHasValidMetadata() async throws {
        let testURL = try await createTestVideo(extension: "mp4")
        defer { try? FileManager.default.removeItem(at: testURL) }

        let realFFmpeg = FFmpegService()
        let realLoader = VideoLoaderService(ffmpeg: realFFmpeg)

        let source = try await realLoader.load(from: testURL)
        XCTAssertGreaterThan(source.durationSeconds, 0)
        XCTAssertGreaterThan(source.naturalSize.width, 0)
        XCTAssertGreaterThan(source.naturalSize.height, 0)
        XCTAssertGreaterThan(source.frameRate, 0)
        realLoader.cleanupTemporaryFiles()
    }

    func testCleanupRemovesTemporaryFiles() async throws {
        let testURL = try await createTestVideo(extension: "mkv")
        defer { try? FileManager.default.removeItem(at: testURL) }

        let realFFmpeg = FFmpegService()
        let realLoader = VideoLoaderService(ffmpeg: realFFmpeg)

        let source = try await realLoader.load(from: testURL)
        let tempURL = source.playableURL
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path))

        realLoader.cleanupTemporaryFiles()
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempURL.path))
    }

    // MARK: - Helper

    private func createTestVideo(extension ext: String) async throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let outputURL = tempDir.appendingPathComponent("test_video.\(ext)")
        try? FileManager.default.removeItem(at: outputURL)

        let ffmpegURL = FFmpegLocator.locate()!
        let process = Process()
        process.executableURL = ffmpegURL
        process.arguments = [
            "-f", "lavfi",
            "-i", "testsrc=duration=1:size=320x240:rate=24",
            "-c:v", ext == "mkv" ? "libx264" : "libx264",
            "-pix_fmt", "yuv420p",
            "-y",
            outputURL.path
        ]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw NSError(domain: "TestHelper", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create test video"
            ])
        }
        return outputURL
    }
}
