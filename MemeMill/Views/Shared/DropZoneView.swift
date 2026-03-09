import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @Binding var isDragOver: Bool
    let onDrop: (URL) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "film")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text("Drop a video file here")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("or press Cmd+O to open")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.6))
            Text("Supports MP4, MOV, MKV, AVI, WebM")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isDragOver ? Color.accentColor.opacity(0.1) : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isDragOver ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
                .padding(20)
        )
        .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url {
                    DispatchQueue.main.async {
                        onDrop(url)
                    }
                }
            }
            return true
        }
    }
}
