import XCTest
@testable import MemeMill

@MainActor
final class GalleryViewModelTests: XCTestCase {

    var tempDir: URL!
    var templateStore: TemplateStore!
    var viewModel: GalleryViewModel!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MemeMill_gallery_test_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        templateStore = TemplateStore(outputDirectory: tempDir)
        viewModel = GalleryViewModel(templateStore: templateStore)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertNil(viewModel.selectedTemplate)
        XCTAssertTrue(viewModel.searchText.isEmpty)
        XCTAssertEqual(viewModel.sortOrder, .newestFirst)
        XCTAssertFalse(viewModel.isRefreshing)
    }

    // MARK: - Filtering

    func testFilteredTemplatesWithNoSearchReturnsAll() {
        templateStore.templates = [
            makeTemplate(fileName: "meme1.gif"),
            makeTemplate(fileName: "meme2.gif"),
        ]
        XCTAssertEqual(viewModel.filteredTemplates.count, 2)
    }

    func testFilteredTemplatesByFileName() {
        templateStore.templates = [
            makeTemplate(fileName: "funny_cat.gif"),
            makeTemplate(fileName: "surprised_pikachu.gif"),
            makeTemplate(fileName: "drake_meme.gif"),
        ]
        viewModel.searchText = "cat"
        XCTAssertEqual(viewModel.filteredTemplates.count, 1)
        XCTAssertEqual(viewModel.filteredTemplates.first?.fileName, "funny_cat.gif")
    }

    func testFilteredTemplatesBySourceVideoName() {
        templateStore.templates = [
            makeTemplate(fileName: "clip1.gif", sourceVideo: "Avengers.mp4"),
            makeTemplate(fileName: "clip2.gif", sourceVideo: "Batman.mkv"),
        ]
        viewModel.searchText = "avengers"
        XCTAssertEqual(viewModel.filteredTemplates.count, 1)
    }

    func testFilteredTemplatesCaseInsensitive() {
        templateStore.templates = [
            makeTemplate(fileName: "MyMeme.gif"),
        ]
        viewModel.searchText = "mymeme"
        XCTAssertEqual(viewModel.filteredTemplates.count, 1)
    }

    // MARK: - Sorting

    func testSortByNewestFirst() {
        let old = makeTemplate(fileName: "old.gif", date: Date(timeIntervalSince1970: 1000))
        let new = makeTemplate(fileName: "new.gif", date: Date(timeIntervalSince1970: 2000))
        templateStore.templates = [old, new]
        viewModel.sortOrder = .newestFirst
        XCTAssertEqual(viewModel.filteredTemplates.first?.fileName, "new.gif")
    }

    func testSortByOldestFirst() {
        let old = makeTemplate(fileName: "old.gif", date: Date(timeIntervalSince1970: 1000))
        let new = makeTemplate(fileName: "new.gif", date: Date(timeIntervalSince1970: 2000))
        templateStore.templates = [old, new]
        viewModel.sortOrder = .oldestFirst
        XCTAssertEqual(viewModel.filteredTemplates.first?.fileName, "old.gif")
    }

    func testSortByName() {
        templateStore.templates = [
            makeTemplate(fileName: "zebra.gif"),
            makeTemplate(fileName: "alpha.gif"),
        ]
        viewModel.sortOrder = .nameAZ
        XCTAssertEqual(viewModel.filteredTemplates.first?.fileName, "alpha.gif")
    }

    func testSortBySizeSmallest() {
        templateStore.templates = [
            makeTemplate(fileName: "big.gif", size: 100000),
            makeTemplate(fileName: "small.gif", size: 1000),
        ]
        viewModel.sortOrder = .sizeSmallest
        XCTAssertEqual(viewModel.filteredTemplates.first?.fileName, "small.gif")
    }

    func testSortBySizeLargest() {
        templateStore.templates = [
            makeTemplate(fileName: "small.gif", size: 1000),
            makeTemplate(fileName: "big.gif", size: 100000),
        ]
        viewModel.sortOrder = .sizeLargest
        XCTAssertEqual(viewModel.filteredTemplates.first?.fileName, "big.gif")
    }

    // MARK: - Delete

    func testDeleteRemovesTemplate() throws {
        let template = makeTemplate(fileName: "to_delete.gif")
        try createDummyGIF(named: template.fileName)
        templateStore.templates = [template]

        viewModel.deleteTemplate(template)
        XCTAssertTrue(templateStore.templates.isEmpty)
    }

    func testDeleteClearsSelectionIfSelected() throws {
        let template = makeTemplate(fileName: "selected.gif")
        try createDummyGIF(named: template.fileName)
        templateStore.templates = [template]
        viewModel.selectedTemplate = template

        viewModel.deleteTemplate(template)
        XCTAssertNil(viewModel.selectedTemplate)
    }

    // MARK: - Refresh

    func testRefreshUpdatesTemplates() async throws {
        try createDummyGIF(named: "refreshed.gif")
        XCTAssertTrue(templateStore.templates.isEmpty)

        await viewModel.refresh()

        XCTAssertEqual(templateStore.templates.count, 1)
        XCTAssertFalse(viewModel.isRefreshing)
    }

    // MARK: - Helpers

    private func makeTemplate(
        fileName: String,
        sourceVideo: String = "movie.mp4",
        date: Date = Date(),
        size: Int64 = 50000
    ) -> GIFTemplate {
        GIFTemplate(
            id: UUID(),
            fileName: fileName,
            fileURL: tempDir.appendingPathComponent(fileName),
            createdAt: date,
            sourceVideoName: sourceVideo,
            timeRange: TimeRange(start: 0, end: 3),
            options: .default,
            fileSizeBytes: size,
            dimensions: CGSize(width: 480, height: 270)
        )
    }

    private func createDummyGIF(named name: String) throws {
        let gifHeader: [UInt8] = [
            0x47, 0x49, 0x46, 0x38, 0x39, 0x61,
            0x01, 0x00, 0x01, 0x00,
            0x00, 0x00, 0x00,
            0x3B
        ]
        try Data(gifHeader).write(to: tempDir.appendingPathComponent(name))
    }
}
