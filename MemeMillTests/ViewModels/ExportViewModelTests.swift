import XCTest
import AVFoundation
@testable import MemeMill

@MainActor
final class ExportViewModelTests: XCTestCase {

    var mockExporter: MockGIFExporter!
    var templateStore: TemplateStore!
    var preferences: UserPreferences!
    var viewModel: ExportViewModel!
    var tempDir: URL!

    override func setUp() {
        super.setUp()
        mockExporter = MockGIFExporter()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MemeMill_export_vm_test_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        templateStore = TemplateStore(outputDirectory: tempDir)
        preferences = UserPreferences()
        preferences.outputDirectory = tempDir
        viewModel = ExportViewModel(
            exporter: mockExporter,
            templateStore: templateStore,
            preferences: preferences
        )
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertFalse(viewModel.isExporting)
        XCTAssertEqual(viewModel.progress, 0)
        XCTAssertNil(viewModel.exportError)
        XCTAssertFalse(viewModel.showExportSuccess)
    }

    // MARK: - Export

    func testExportCallsExporter() async throws {
        let source = makeSource()
        let timeRange = TimeRange(start: 0, end: 3)

        viewModel.exportGIF(from: source, timeRange: timeRange)

        // Wait for the task to complete
        try await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertEqual(mockExporter.exportCallCount, 1)
        XCTAssertEqual(mockExporter.lastTimeRange, timeRange)
        XCTAssertFalse(viewModel.isExporting)
        XCTAssertTrue(viewModel.showExportSuccess)
    }

    func testExportSetsErrorOnFailure() async throws {
        mockExporter.exportResult = .failure(ExportError.ffmpegNotFound)
        let source = makeSource()

        viewModel.exportGIF(from: source, timeRange: TimeRange(start: 0, end: 3))

        try await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertNotNil(viewModel.exportError)
        XCTAssertFalse(viewModel.isExporting)
    }

    func testCancelExportCallsExporterCancel() async {
        viewModel.cancelExport()

        // Give cancel a moment to propagate
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(mockExporter.cancelCalled)
        XCTAssertFalse(viewModel.isExporting)
    }

    func testExportOptionsFromPreferences() {
        let customOptions = GIFExportOptions(
            fps: 24, scale: .full, quality: .maximum, speed: 2.0, loopCount: 3
        )
        preferences.lastUsedExportOptions = customOptions
        let vm = ExportViewModel(
            exporter: mockExporter,
            templateStore: templateStore,
            preferences: preferences
        )
        XCTAssertEqual(vm.options, customOptions)
    }

    // MARK: - Helpers

    private func makeSource() -> VideoSource {
        VideoSource(
            id: UUID(),
            originalURL: URL(fileURLWithPath: "/test.mp4"),
            playableURL: URL(fileURLWithPath: "/test.mp4"),
            wasRemuxed: false,
            duration: CMTime(seconds: 60, preferredTimescale: 600),
            naturalSize: CGSize(width: 1920, height: 1080),
            frameRate: 24,
            fileSize: 10_000_000,
            fileName: "test.mp4"
        )
    }
}
