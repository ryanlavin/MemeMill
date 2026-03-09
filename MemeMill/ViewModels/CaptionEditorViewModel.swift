import SwiftUI
import Combine

@MainActor
final class CaptionEditorViewModel: ObservableObject {
    @Published var layout: CaptionLayout = .empty
    @Published var isRendering = false
    @Published var renderProgress: Double = 0.0
    @Published var renderError: String?
    @Published var renderSuccess = false
    @Published var previewFrame: NSImage?

    private let captionRenderer: CaptionRendererProtocol
    private let templateStore: TemplateStore
    let sourceTemplate: GIFTemplate

    private var previewDebounceTask: Task<Void, Never>?

    init(
        sourceTemplate: GIFTemplate,
        captionRenderer: CaptionRendererProtocol,
        templateStore: TemplateStore
    ) {
        self.sourceTemplate = sourceTemplate
        self.captionRenderer = captionRenderer
        self.templateStore = templateStore
        loadPreviewFrame()
    }

    func updatePreview() {
        previewDebounceTask?.cancel()
        previewDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 150_000_000) // 150ms debounce
            guard !Task.isCancelled else { return }
            guard let frame = previewFrame else { return }
            let captioned = captionRenderer.previewCaption(on: frame, layout: layout)
            self.previewFrame = captioned
        }
    }

    func renderCaptionedGIF() async {
        isRendering = true
        renderProgress = 0
        renderError = nil
        renderSuccess = false

        let timestamp = DateFormatter.localizedString(
            from: Date(), dateStyle: .none, timeStyle: .medium
        ).replacingOccurrences(of: ":", with: "-")
        let baseName = sourceTemplate.fileName.replacingOccurrences(of: ".gif", with: "")
        let outputFileName = "\(baseName)_captioned_\(timestamp).gif"
        let outputURL = sourceTemplate.fileURL.deletingLastPathComponent()
            .appendingPathComponent(outputFileName)

        do {
            try captionRenderer.renderCaptions(
                on: sourceTemplate.fileURL,
                layout: layout,
                outputURL: outputURL,
                progressHandler: { [weak self] progress in
                    Task { @MainActor [weak self] in
                        self?.renderProgress = progress
                    }
                }
            )
            await templateStore.refresh()
            renderSuccess = true
        } catch {
            renderError = error.localizedDescription
        }

        isRendering = false
    }

    func availableFonts() -> [String] {
        let manager = NSFontManager.shared
        return manager.availableFontFamilies.sorted()
    }

    private func loadPreviewFrame() {
        guard let image = NSImage(contentsOf: sourceTemplate.fileURL) else { return }
        // Get first frame
        previewFrame = image
    }
}
