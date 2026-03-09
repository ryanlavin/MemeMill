import SwiftUI

@MainActor
final class ExportViewModel: ObservableObject {
    @Published var options: GIFExportOptions = .default
    @Published var isExporting = false
    @Published var progress: Double = 0.0
    @Published var exportError: String?
    @Published var showExportSuccess = false
    @Published var lastExportedTemplate: GIFTemplate?

    private let exporter: GIFExporterProtocol
    private let templateStore: TemplateStore
    private let preferences: UserPreferences
    private var exportTask: Task<Void, Never>?

    init(
        exporter: GIFExporterProtocol,
        templateStore: TemplateStore,
        preferences: UserPreferences
    ) {
        self.exporter = exporter
        self.templateStore = templateStore
        self.preferences = preferences
        self.options = preferences.lastUsedExportOptions
    }

    func exportGIF(from source: VideoSource, timeRange: TimeRange) {
        guard !isExporting else { return }
        isExporting = true
        progress = 0
        exportError = nil

        exportTask = Task {
            do {
                let outputDir = preferences.outputDirectory
                try FileManager.default.createDirectory(
                    at: outputDir,
                    withIntermediateDirectories: true
                )

                let template = try await exporter.exportGIF(
                    from: source,
                    timeRange: timeRange,
                    options: options,
                    outputDirectory: outputDir,
                    progressHandler: { [weak self] value in
                        Task { @MainActor [weak self] in
                            self?.progress = value
                        }
                    }
                )

                try templateStore.saveMetadata(for: template)
                await templateStore.refresh()

                preferences.lastUsedExportOptions = options
                lastExportedTemplate = template
                showExportSuccess = true
            } catch let error as ExportError {
                exportError = error.errorDescription
            } catch {
                exportError = error.localizedDescription
            }

            isExporting = false
            progress = 0
        }
    }

    func cancelExport() {
        exportTask?.cancel()
        Task {
            await exporter.cancel()
        }
        isExporting = false
        progress = 0
    }

    var estimatedFileSizeText: String {
        // Rough estimate: fps * duration * scale * quality_factor * base_bytes_per_frame
        return "Size depends on content"
    }
}
