import SwiftUI

struct GIFDetailView: View {
    let template: GIFTemplate
    let onCaption: () -> Void
    let onReveal: () -> Void
    let onCopy: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 16) {
            // Full-size GIF preview
            AnimatedGIFView(url: template.fileURL)
                .frame(maxWidth: 600, maxHeight: 400)
                .cornerRadius(8)

            // Metadata
            VStack(alignment: .leading, spacing: 8) {
                metadataRow("File", template.fileName)
                metadataRow("Source", template.sourceVideoName)
                metadataRow("Size", template.fileSizeFormatted)
                metadataRow("Duration", template.durationFormatted)
                metadataRow("Dimensions",
                    "\(Int(template.dimensions.width))x\(Int(template.dimensions.height))")
                metadataRow("Created",
                    template.createdAt.formatted(date: .abbreviated, time: .shortened))
                metadataRow("FPS", "\(template.options.fps)")
                metadataRow("Scale", template.options.scale.rawValue)
                metadataRow("Quality", template.options.quality.rawValue.capitalized)
            }
            .frame(maxWidth: 400, alignment: .leading)

            Divider()

            // Actions
            HStack(spacing: 12) {
                Button(action: onCaption) {
                    Label("Add Caption", systemImage: "text.bubble")
                }
                .buttonStyle(.borderedProminent)

                Button(action: onReveal) {
                    Label("Reveal in Finder", systemImage: "folder")
                }
                .buttonStyle(.bordered)

                Button(action: onCopy) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)

                Button(action: { showDeleteConfirmation = true }) {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding()
        .alert("Delete Template?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("This will permanently delete \(template.fileName).")
        }
    }

    private func metadataRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .trailing)
            Text(value)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .font(.caption)
    }
}
