import XCTest
@testable import MemeMill

final class TemplateStoreTests: XCTestCase {

    var tempDir: URL!
    var store: TemplateStore!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MemeMill_store_test_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        store = TemplateStore(outputDirectory: tempDir)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        store = nil
        super.tearDown()
    }

    // MARK: - Refresh

    func testRefreshLoadsGIFsFromDirectory() async throws {
        // Create dummy GIF files
        try createDummyGIF(named: "test1.gif")
        try createDummyGIF(named: "test2.gif")

        await store.refresh()

        XCTAssertEqual(store.templates.count, 2)
    }

    func testRefreshWithEmptyDirectoryReturnsEmpty() async {
        await store.refresh()
        XCTAssertTrue(store.templates.isEmpty)
    }

    func testRefreshWithNonExistentDirectoryReturnsEmpty() async {
        let nonExistent = FileManager.default.temporaryDirectory
            .appendingPathComponent("nonexistent_\(UUID().uuidString)")
        let store = TemplateStore(outputDirectory: nonExistent)
        await store.refresh()
        XCTAssertTrue(store.templates.isEmpty)
    }

    func testRefreshIgnoresNonGIFFiles() async throws {
        try createDummyGIF(named: "test.gif")
        try "not a gif".write(
            to: tempDir.appendingPathComponent("readme.txt"),
            atomically: true, encoding: .utf8
        )

        await store.refresh()

        XCTAssertEqual(store.templates.count, 1)
        XCTAssertEqual(store.templates.first?.fileName, "test.gif")
    }

    // MARK: - Metadata

    func testRefreshWithCompanionJSONLoadsFullMetadata() async throws {
        let template = makeTemplate(fileName: "test_meta.gif")
        try createDummyGIF(named: template.fileName)
        try store.saveMetadata(for: template)

        await store.refresh()

        XCTAssertEqual(store.templates.count, 1)
        let loaded = store.templates.first!
        XCTAssertEqual(loaded.sourceVideoName, template.sourceVideoName)
        XCTAssertEqual(loaded.timeRange, template.timeRange)
    }

    func testRefreshWithoutJSONCreatesMinimalTemplate() async throws {
        try createDummyGIF(named: "orphan.gif")

        await store.refresh()

        XCTAssertEqual(store.templates.count, 1)
        let loaded = store.templates.first!
        XCTAssertEqual(loaded.fileName, "orphan.gif")
        XCTAssertEqual(loaded.sourceVideoName, "Unknown")
    }

    func testSaveMetadataWritesJSONFile() throws {
        let template = makeTemplate(fileName: "metadata_test.gif")
        try createDummyGIF(named: template.fileName)
        try store.saveMetadata(for: template)

        let jsonURL = tempDir.appendingPathComponent("metadata_test.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: jsonURL.path))

        let data = try Data(contentsOf: jsonURL)
        let decoded = try JSONDecoder().decode(GIFTemplate.self, from: data)
        XCTAssertEqual(decoded.fileName, template.fileName)
    }

    // MARK: - Delete

    func testDeleteRemovesGIFAndJSON() throws {
        let template = makeTemplate(fileName: "delete_test.gif")
        try createDummyGIF(named: template.fileName)
        try store.saveMetadata(for: template)

        store.templates = [template]
        try store.delete(template)

        XCTAssertFalse(FileManager.default.fileExists(
            atPath: tempDir.appendingPathComponent("delete_test.gif").path))
        XCTAssertFalse(FileManager.default.fileExists(
            atPath: tempDir.appendingPathComponent("delete_test.json").path))
        XCTAssertTrue(store.templates.isEmpty)
    }

    // MARK: - Sort Order

    func testTemplatesSortedNewestFirst() async throws {
        try createDummyGIF(named: "old.gif")
        // Small delay to ensure different creation dates
        try await Task.sleep(nanoseconds: 100_000_000)
        try createDummyGIF(named: "new.gif")

        await store.refresh()

        XCTAssertEqual(store.templates.count, 2)
        // Newest should be first
        XCTAssertEqual(store.templates.first?.fileName, "new.gif")
    }

    // MARK: - Helpers

    private func createDummyGIF(named name: String) throws {
        // Create a minimal valid GIF file (GIF89a header + minimal data)
        let gifHeader: [UInt8] = [
            0x47, 0x49, 0x46, 0x38, 0x39, 0x61, // GIF89a
            0x01, 0x00, 0x01, 0x00, // 1x1 pixels
            0x00, 0x00, 0x00, // flags, bg, aspect
            0x3B // trailer
        ]
        let data = Data(gifHeader)
        try data.write(to: tempDir.appendingPathComponent(name))
    }

    private func makeTemplate(fileName: String) -> GIFTemplate {
        GIFTemplate(
            id: UUID(),
            fileName: fileName,
            fileURL: tempDir.appendingPathComponent(fileName),
            createdAt: Date(),
            sourceVideoName: "test_movie.mp4",
            timeRange: TimeRange(start: 1.0, end: 4.0),
            options: .default,
            fileSizeBytes: 1234,
            dimensions: CGSize(width: 480, height: 270)
        )
    }
}
