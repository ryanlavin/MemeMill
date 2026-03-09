import Foundation
@testable import MemeMill

final class MockGIFExporter: GIFExporterProtocol {
    var exportResult: Result<GIFTemplate, Error>?
    var exportCallCount = 0
    var lastSource: VideoSource?
    var lastTimeRange: TimeRange?
    var lastOptions: GIFExportOptions?
    var cancelCalled = false

    func exportGIF(
        from source: VideoSource,
        timeRange: TimeRange,
        options: GIFExportOptions,
        outputDirectory: URL,
        progressHandler: (@Sendable (Double) -> Void)?
    ) async throws -> GIFTemplate {
        exportCallCount += 1
        lastSource = source
        lastTimeRange = timeRange
        lastOptions = options

        progressHandler?(0.5)
        progressHandler?(1.0)

        if let result = exportResult {
            return try result.get()
        }

        return GIFTemplate(
            id: UUID(),
            fileName: "test_export.gif",
            fileURL: outputDirectory.appendingPathComponent("test_export.gif"),
            createdAt: Date(),
            sourceVideoName: source.fileName,
            timeRange: timeRange,
            options: options,
            fileSizeBytes: 50000,
            dimensions: CGSize(width: 480, height: 270)
        )
    }

    func cancel() async { cancelCalled = true }
}
