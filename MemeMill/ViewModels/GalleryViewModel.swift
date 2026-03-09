import SwiftUI

@MainActor
final class GalleryViewModel: ObservableObject {
    @Published var selectedTemplate: GIFTemplate?
    @Published var searchText: String = ""
    @Published var sortOrder: SortOrder = .newestFirst
    @Published var isRefreshing = false

    enum SortOrder: String, CaseIterable, Identifiable {
        case newestFirst = "Newest First"
        case oldestFirst = "Oldest First"
        case nameAZ = "Name (A-Z)"
        case sizeSmallest = "Size (Smallest)"
        case sizeLargest = "Size (Largest)"

        var id: String { rawValue }
    }

    let templateStore: TemplateStore

    init(templateStore: TemplateStore) {
        self.templateStore = templateStore
    }

    var filteredTemplates: [GIFTemplate] {
        var templates = templateStore.templates

        if !searchText.isEmpty {
            templates = templates.filter {
                $0.fileName.localizedCaseInsensitiveContains(searchText) ||
                $0.sourceVideoName.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sortOrder {
        case .newestFirst:
            templates.sort { $0.createdAt > $1.createdAt }
        case .oldestFirst:
            templates.sort { $0.createdAt < $1.createdAt }
        case .nameAZ:
            templates.sort { $0.fileName.localizedCompare($1.fileName) == .orderedAscending }
        case .sizeSmallest:
            templates.sort { $0.fileSizeBytes < $1.fileSizeBytes }
        case .sizeLargest:
            templates.sort { $0.fileSizeBytes > $1.fileSizeBytes }
        }

        return templates
    }

    func refresh() async {
        isRefreshing = true
        await templateStore.refresh()
        isRefreshing = false
    }

    func deleteTemplate(_ template: GIFTemplate) {
        do {
            try templateStore.delete(template)
            if selectedTemplate?.id == template.id {
                selectedTemplate = nil
            }
        } catch {
            // Silently handle - template may already be deleted
        }
    }

    func revealInFinder(_ template: GIFTemplate) {
        NSWorkspace.shared.selectFile(
            template.fileURL.path,
            inFileViewerRootedAtPath: template.fileURL.deletingLastPathComponent().path
        )
    }

    func copyToClipboard(_ template: GIFTemplate) {
        guard let image = NSImage(contentsOf: template.fileURL) else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }
}
