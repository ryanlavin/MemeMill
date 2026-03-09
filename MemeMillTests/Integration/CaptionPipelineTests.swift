import XCTest
import ImageIO
@testable import MemeMill

final class CaptionPipelineTests: XCTestCase {

    var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MemeMill_caption_pipeline_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testFullPipelineExportAndCaption() async throws {
        // Step 1: Create a test video
        let videoURL = try createTestVideo()
        defer { try? FileManager.default.removeItem(at: videoURL) }

        // Step 2: Load the video
        let ffmpeg = FFmpegService()
        let loader = VideoLoaderService(ffmpeg: ffmpeg)
        let source = try await loader.load(from: videoURL)
        defer { loader.cleanupTemporaryFiles() }

        // Step 3: Export a GIF
        let exporter = GIFExportService(ffmpeg: ffmpeg)
        let template = try await exporter.exportGIF(
            from: source,
            timeRange: TimeRange(start: 0, end: 0.5),
            options: GIFExportOptions(
                fps: 10,
                scale: .half,
                quality: .medium,
                speed: 1.0,
                loopCount: 0
            ),
            outputDirectory: tempDir,
            progressHandler: nil
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: template.fileURL.path))

        // Verify the GIF has frames
        guard let gifSource = CGImageSourceCreateWithURL(template.fileURL as CFURL, nil) else {
            XCTFail("Cannot read exported GIF")
            return
        }
        let originalFrameCount = CGImageSourceGetCount(gifSource)
        XCTAssertGreaterThan(originalFrameCount, 0)

        // Step 4: Add captions to the GIF
        let renderer = CaptionRenderer()
        let captionedURL = tempDir.appendingPathComponent("captioned_output.gif")
        let layout = CaptionLayout(
            topText: "WHEN YOU SHIP CODE",
            bottomText: "ON A FRIDAY",
            topStyle: .memeDefault,
            bottomStyle: .memeDefault
        )

        try renderer.renderCaptions(
            on: template.fileURL,
            layout: layout,
            outputURL: captionedURL,
            progressHandler: nil
        )

        // Step 5: Verify the captioned GIF
        XCTAssertTrue(FileManager.default.fileExists(atPath: captionedURL.path))

        guard let captionedSource = CGImageSourceCreateWithURL(captionedURL as CFURL, nil) else {
            XCTFail("Cannot read captioned GIF")
            return
        }

        let captionedFrameCount = CGImageSourceGetCount(captionedSource)
        XCTAssertEqual(captionedFrameCount, originalFrameCount,
            "Captioned GIF should have the same frame count as original")

        // Verify file size is reasonable (captioned should be similar or larger)
        let originalSize = try FileManager.default.attributesOfItem(
            atPath: template.fileURL.path
        )[.size] as? Int64 ?? 0
        let captionedSize = try FileManager.default.attributesOfItem(
            atPath: captionedURL.path
        )[.size] as? Int64 ?? 0

        XCTAssertGreaterThan(captionedSize, 0)
        XCTAssertGreaterThan(originalSize, 0)
    }

    func testTemplateStoreMetadataRoundTrip() throws {
        let store = TemplateStore(outputDirectory: tempDir)

        let template = GIFTemplate(
            id: UUID(),
            fileName: "test.gif",
            fileURL: tempDir.appendingPathComponent("test.gif"),
            createdAt: Date(),
            sourceVideoName: "movie.mp4",
            timeRange: TimeRange(start: 1.5, end: 4.5),
            options: GIFExportOptions(
                fps: 24,
                scale: .twoThirds,
                quality: .maximum,
                speed: 1.5,
                loopCount: 3
            ),
            fileSizeBytes: 123456,
            dimensions: CGSize(width: 640, height: 360)
        )

        // Create dummy GIF file
        let gifHeader: [UInt8] = [0x47, 0x49, 0x46, 0x38, 0x39, 0x61,
                                  0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x3B]
        try Data(gifHeader).write(to: template.fileURL)

        // Save metadata
        try store.saveMetadata(for: template)

        // Verify JSON exists
        let jsonURL = tempDir.appendingPathComponent("test.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: jsonURL.path))

        // Load and verify
        let data = try Data(contentsOf: jsonURL)
        let loaded = try JSONDecoder().decode(GIFTemplate.self, from: data)

        XCTAssertEqual(loaded.fileName, template.fileName)
        XCTAssertEqual(loaded.sourceVideoName, "movie.mp4")
        XCTAssertEqual(loaded.timeRange.start, 1.5)
        XCTAssertEqual(loaded.timeRange.end, 4.5)
        XCTAssertEqual(loaded.options.fps, 24)
        XCTAssertEqual(loaded.options.scale, .twoThirds)
        XCTAssertEqual(loaded.options.quality, .maximum)
        XCTAssertEqual(loaded.options.speed, 1.5)
        XCTAssertEqual(loaded.options.loopCount, 3)
    }

    // MARK: - Helper

    private func createTestVideo() throws -> URL {
        let outputURL = tempDir.appendingPathComponent("pipeline_test.mp4")
        let ffmpegURL = FFmpegLocator.locate()!
        let process = Process()
        process.executableURL = ffmpegURL
        process.arguments = [
            "-f", "lavfi",
            "-i", "testsrc=duration=1:size=320x240:rate=24",
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
