import SwiftUI

struct VideoEditorView: View {
    @EnvironmentObject var preferences: UserPreferences
    @State private var videoURL: URL?
    @State private var isDragOver = false

    var body: some View {
        Group {
            if videoURL != nil {
                Text("Video loaded - editor coming soon")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                DropZoneView(isDragOver: $isDragOver) { url in
                    videoURL = url
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openVideoFile)) { notification in
            if let url = notification.object as? URL {
                videoURL = url
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openFilePicker)) { _ in
            showFilePicker()
        }
    }

    private func showFilePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie, .mpeg4Movie, .quickTimeMovie, .avi]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            videoURL = url
        }
    }
}
