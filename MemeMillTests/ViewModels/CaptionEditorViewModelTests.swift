import XCTest
@testable import MemeMill

@MainActor
final class CaptionEditorViewModelTests: XCTestCase {

    var tempDir: URL!
    var mockRenderer: MockCaptionRenderer!
    var templateStore: TemplateStore!
    var sourceTemplate: GIFTemplate!
    var viewModel: CaptionEditorViewModel!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MemeMill_caption_test_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Create a dummy GIF for the source template
        let gifURL = tempDir.appendingPathComponent("source.gif")
        let gifHeader: [UInt8] = [
            0x47, 0x49, 0x46, 0x38, 0x39, 0x61,
            0x01, 0x00, 0x01, 0x00,
            0x00, 0x00, 0x00,
            0x3B
        ]
        try? Data(gifHeader).write(to: gifURL)

        sourceTemplate = GIFTemplate(
            id: UUID(),
            fileName: "source.gif",
            fileURL: gifURL,
            createdAt: Date(),
            sourceVideoName: "movie.mp4",
            timeRange: TimeRange(start: 0, end: 3),
            options: .default,
            fileSizeBytes: 1234,
            dimensions: CGSize(width: 320, height: 240)
        )

        mockRenderer = MockCaptionRenderer()
        templateStore = TemplateStore(outputDirectory: tempDir)
        viewModel = CaptionEditorViewModel(
            sourceTemplate: sourceTemplate,
            captionRenderer: mockRenderer,
            templateStore: templateStore
        )
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertEqual(viewModel.layout, .empty)
        XCTAssertFalse(viewModel.isRendering)
        XCTAssertEqual(viewModel.renderProgress, 0)
        XCTAssertNil(viewModel.renderError)
        XCTAssertFalse(viewModel.renderSuccess)
    }

    func testSourceTemplateIsSet() {
        XCTAssertEqual(viewModel.sourceTemplate.fileName, "source.gif")
    }

    // MARK: - Render

    func testRenderCallsRenderer() async {
        viewModel.layout = CaptionLayout(
            topText: "Hello",
            bottomText: "World",
            topStyle: .memeDefault,
            bottomStyle: .memeDefault
        )
        await viewModel.renderCaptionedGIF()

        XCTAssertEqual(mockRenderer.renderCallCount, 1)
        XCTAssertEqual(mockRenderer.lastLayout?.topText, "Hello")
        XCTAssertEqual(mockRenderer.lastLayout?.bottomText, "World")
        XCTAssertTrue(viewModel.renderSuccess)
        XCTAssertFalse(viewModel.isRendering)
    }

    func testRenderSetsErrorOnFailure() async {
        mockRenderer.renderResult = .failure(
            ExportError.captionRenderingFailed("test error")
        )

        viewModel.layout = CaptionLayout(
            topText: "Test",
            bottomText: "",
            topStyle: .memeDefault,
            bottomStyle: .memeDefault
        )
        await viewModel.renderCaptionedGIF()

        XCTAssertNotNil(viewModel.renderError)
        XCTAssertFalse(viewModel.renderSuccess)
        XCTAssertFalse(viewModel.isRendering)
    }

    // MARK: - Available Fonts

    func testAvailableFontsReturnsNonEmpty() {
        let fonts = viewModel.availableFonts()
        XCTAssertFalse(fonts.isEmpty)
    }

    func testAvailableFontsAreSorted() {
        let fonts = viewModel.availableFonts()
        let sorted = fonts.sorted()
        XCTAssertEqual(fonts, sorted)
    }

    // MARK: - Layout

    func testLayoutHasContentWithTopText() {
        viewModel.layout.topText = "Hello"
        XCTAssertTrue(viewModel.layout.hasContent)
    }

    func testLayoutHasNoContentWhenEmpty() {
        XCTAssertFalse(viewModel.layout.hasContent)
    }
}
