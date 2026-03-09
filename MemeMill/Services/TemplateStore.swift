import Foundation
import Combine

final class TemplateStore: ObservableObject, TemplateStoreProtocol {
    @Published var templates: [GIFTemplate] = []
    @Published var outputDirectory: URL

    private let fileManager = FileManager.default

    init(outputDirectory: URL? = nil) {
        let defaultDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop/MemeTemplates", isDirectory: true)
        self.outputDirectory = outputDirectory ?? defaultDir
    }

    func refresh() async {
        let dir = outputDirectory
        guard fileManager.fileExists(atPath: dir.path) else {
            await MainActor.run { templates = [] }
            return
        }

        let gifURLs = (try? fileManager.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ))?.filter { $0.pathExtension.lowercased() == "gif" } ?? []

        var loaded: [GIFTemplate] = []
        for url in gifURLs {
            let metadataURL = url.deletingPathExtension().appendingPathExtension("json")
            if let data = try? Data(contentsOf: metadataURL),
               let template = try? JSONDecoder().decode(GIFTemplate.self, from: data) {
                loaded.append(template)
            } else {
                let attrs = try? fileManager.attributesOfItem(atPath: url.path)
                loaded.append(GIFTemplate(
                    id: UUID(),
                    fileName: url.lastPathComponent,
                    fileURL: url,
                    createdAt: (attrs?[.creationDate] as? Date) ?? Date(),
                    sourceVideoName: "Unknown",
                    timeRange: TimeRange(start: 0, end: 0),
                    options: .default,
                    fileSizeBytes: (attrs?[.size] as? Int64) ?? 0,
                    dimensions: .zero
                ))
            }
        }

        await MainActor.run {
            templates = loaded.sorted { $0.createdAt > $1.createdAt }
        }
    }

    func saveMetadata(for template: GIFTemplate) throws {
        let metadataURL = template.fileURL
            .deletingPathExtension()
            .appendingPathExtension("json")
        let data = try JSONEncoder().encode(template)
        try data.write(to: metadataURL)
    }

    func delete(_ template: GIFTemplate) throws {
        try fileManager.removeItem(at: template.fileURL)
        let metadataURL = template.fileURL
            .deletingPathExtension()
            .appendingPathExtension("json")
        try? fileManager.removeItem(at: metadataURL)
        templates.removeAll { $0.id == template.id }
    }
}
