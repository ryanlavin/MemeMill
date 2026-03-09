import XCTest
@testable import MemeMill

final class GIFExportServiceTests: XCTestCase {

    var mockFFmpeg: MockFFmpegService!
    var exportService: GIFExportService!

    override func setUp() {
        super.setUp()
        mockFFmpeg = MockFFmpegService()
        exportService = GIFExportService(ffmpeg: mockFFmpeg)
    }

    // MARK: - Filter Base

    func testBuildFilterBaseNormalSpeed() {
        let filter = exportService.buildFilterBase(fps: 15, width: 960, speed: 1.0)
        XCTAssertEqual(filter, "fps=15,scale=960:-1:flags=lanczos")
        XCTAssertFalse(filter.contains("setpts"))
    }

    func testBuildFilterBaseWithSpeedUp() {
        let filter = exportService.buildFilterBase(fps: 15, width: 960, speed: 2.0)
        XCTAssertTrue(filter.contains("setpts="))
        XCTAssertTrue(filter.contains("0.5"))
        XCTAssertTrue(filter.contains("fps=15"))
    }

    func testBuildFilterBaseWithSlowDown() {
        let filter = exportService.buildFilterBase(fps: 10, width: 480, speed: 0.5)
        XCTAssertTrue(filter.contains("setpts="))
        XCTAssertTrue(filter.contains("2.0"))
        XCTAssertTrue(filter.contains("fps=10"))
        XCTAssertTrue(filter.contains("scale=480"))
    }

    // MARK: - Pass 1 Arguments

    func testPass1ArgumentsStructure() {
        let args = exportService.buildPass1Arguments(
            inputPath: "/path/to/video.mp4",
            timeRange: TimeRange(start: 5.0, end: 8.0),
            filterBase: "fps=15,scale=960:-1:flags=lanczos",
            statsMode: "diff",
            palettePath: "/tmp/palette.png"
        )

        XCTAssertTrue(args.contains("-ss"))
        XCTAssertTrue(args.contains("5.0"))
        XCTAssertTrue(args.contains("-t"))
        XCTAssertTrue(args.contains("3.0"))
        XCTAssertTrue(args.contains("-i"))
        XCTAssertTrue(args.contains("/path/to/video.mp4"))
        XCTAssertTrue(args.contains("-vf"))
        XCTAssertTrue(args.contains("-y"))
        XCTAssertTrue(args.contains("/tmp/palette.png"))

        // Check filter contains palettegen
        let vfIndex = args.firstIndex(of: "-vf")!
        let filterValue = args[vfIndex + 1]
        XCTAssertTrue(filterValue.contains("palettegen=stats_mode=diff"))
    }

    // MARK: - Pass 2 Arguments

    func testPass2ArgumentsStructure() {
        let args = exportService.buildPass2Arguments(
            inputPath: "/path/to/video.mp4",
            timeRange: TimeRange(start: 5.0, end: 8.0),
            filterBase: "fps=15,scale=960:-1:flags=lanczos",
            ditherAlgorithm: "floyd_steinberg",
            palettePath: "/tmp/palette.png",
            outputPath: "/output/test.gif",
            loopCount: 0
        )

        XCTAssertTrue(args.contains("-ss"))
        XCTAssertTrue(args.contains("-i"))
        XCTAssertTrue(args.contains("/tmp/palette.png"))
        XCTAssertTrue(args.contains("-lavfi"))
        XCTAssertTrue(args.contains("-loop"))
        XCTAssertTrue(args.contains("0"))
        XCTAssertTrue(args.contains("/output/test.gif"))

        let lavfiIndex = args.firstIndex(of: "-lavfi")!
        let filterValue = args[lavfiIndex + 1]
        XCTAssertTrue(filterValue.contains("paletteuse=dither=floyd_steinberg"))
    }

    // MARK: - Export Validation

    func testExportThrowsForInvalidTimeRange() async {
        let source = makeTestVideoSource()
        let invalidRange = TimeRange(start: 5.0, end: 2.0)

        do {
            _ = try await exportService.exportGIF(
                from: source,
                timeRange: invalidRange,
                options: .default,
                outputDirectory: FileManager.default.temporaryDirectory,
                progressHandler: nil
            )
            XCTFail("Should throw for invalid time range")
        } catch let error as ExportError {
            XCTAssertEqual(error, .invalidTimeRange)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testExportCallsFFmpegTwice() async throws {
        let source = makeTestVideoSource()
        let outputDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MemeMill_test_\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: outputDir) }

        // Need to create a dummy file at the output path since the mock doesn't actually create it
        mockFFmpeg.runResults = [
            .success(Data()),
            .success(Data())
        ]

        // Mock won't create the actual file, so we need to pre-create
        // Actually, the export service checks file attrs after export
        // Let's just verify the mock is called correctly
        do {
            _ = try await exportService.exportGIF(
                from: source,
                timeRange: TimeRange(start: 0, end: 3.0),
                options: .default,
                outputDirectory: outputDir,
                progressHandler: nil
            )
        } catch {
            // May fail on file attrs since mock doesn't create file - that's ok
        }

        XCTAssertEqual(mockFFmpeg.runCallCount, 2, "Should call FFmpeg twice (palette + GIF)")
        let pass1Joined = mockFFmpeg.runArguments[0].joined(separator: " ")
        let pass2Joined = mockFFmpeg.runArguments[1].joined(separator: " ")
        XCTAssertTrue(pass1Joined.contains("palettegen"), "Pass 1 should contain palettegen")
        XCTAssertTrue(pass2Joined.contains("paletteuse"), "Pass 2 should contain paletteuse")
    }

    func testExportProgressHandlerCalled() async throws {
        let source = makeTestVideoSource()
        let outputDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MemeMill_test_\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: outputDir) }

        var progressValues: [Double] = []
        let lock = NSLock()

        do {
            _ = try await exportService.exportGIF(
                from: source,
                timeRange: TimeRange(start: 0, end: 3.0),
                options: .default,
                outputDirectory: outputDir,
                progressHandler: { value in
                    lock.lock()
                    progressValues.append(value)
                    lock.unlock()
                }
            )
        } catch {
            // May fail on file attrs
        }

        // Should have at least the initial and midpoint progress calls
        XCTAssertFalse(progressValues.isEmpty, "Progress handler should be called")
    }

    func testCancelCallsFFmpegCancel() async {
        await exportService.cancel()
        XCTAssertTrue(mockFFmpeg.cancelCalled)
    }

    // MARK: - Integration Test

    func testFullGIFExportPipeline() async throws {
        // Create a real test video and export a real GIF
        let testVideoURL = try await createTestVideo()
        defer { try? FileManager.default.removeItem(at: testVideoURL) }

        let outputDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MemeMill_export_test_\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: outputDir) }

        let realFFmpeg = FFmpegService()
        let realExporter = GIFExportService(ffmpeg: realFFmpeg)

        let realLoader = VideoLoaderService(ffmpeg: realFFmpeg)
        let source = try await realLoader.load(from: testVideoURL)

        let template = try await realExporter.exportGIF(
            from: source,
            timeRange: TimeRange(start: 0, end: 0.5),
            options: GIFExportOptions(fps: 10, scale: .half, quality: .medium, speed: 1.0, loopCount: 0),
            outputDirectory: outputDir,
            progressHandler: nil
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: template.fileURL.path))
        XCTAssertGreaterThan(template.fileSizeBytes, 0)
        XCTAssertEqual(template.fileURL.pathExtension, "gif")
        XCTAssertTrue(template.fileName.contains("test_video"))

        realLoader.cleanupTemporaryFiles()
    }

    // MARK: - Helpers

    private func makeTestVideoSource() -> VideoSource {
        VideoSource(
            id: UUID(),
            originalURL: URL(fileURLWithPath: "/path/to/video.mp4"),
            playableURL: URL(fileURLWithPath: "/path/to/video.mp4"),
            wasRemuxed: false,
            duration: .init(seconds: 10, preferredTimescale: 600),
            naturalSize: CGSize(width: 1920, height: 1080),
            frameRate: 24,
            fileSize: 10_000_000,
            fileName: "test_video.mp4"
        )
    }

    private func createTestVideo() async throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let outputURL = tempDir.appendingPathComponent("test_video.mp4")
        try? FileManager.default.removeItem(at: outputURL)

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
