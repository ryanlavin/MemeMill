import Foundation

protocol GIFExporterProtocol {
    func exportGIF(
        from source: VideoSource,
        timeRange: TimeRange,
        options: GIFExportOptions,
        outputDirectory: URL,
        progressHandler: (@Sendable (Double) -> Void)?
    ) async throws -> GIFTemplate
    func cancel() async
}
